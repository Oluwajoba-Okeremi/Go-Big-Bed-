import Foundation
import Combine

final class SleepSessionStore: ObservableObject {
    /// Called whenever a session is definitively ended (manual, auto, or rescue).
    /// We hand back the (start, effectiveEnd). Caller writes to HealthKit.
    var onAutoEnded: ((Date, Date) -> Void)?

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var startDate: Date?
    @Published private(set) var elapsed: TimeInterval = 0  // last known (UI convenience)

    static let minSeconds: TimeInterval = 30 * 60
    private let tickInterval: TimeInterval = 1

    /// Noon boundary (Health app convention)
    private let cutoffHour: Int = 12

    private let kStartDate = "sleeptrack.currentStart"
    private let kIsRunning = "sleeptrack.isRunning"

    private var ticker: AnyCancellable?
    private let motionGuard = MotionGuard()

    // MARK: - PUBLIC BOOTSTRAP
    func bootstrap() {
        let ud = UserDefaults.standard
        if let saved = ud.object(forKey: kStartDate) as? Date,
           ud.bool(forKey: kIsRunning) == true {

            self.startDate = saved
            self.isRunning = true

            // Even if the ticker was dead for hours, recompute from wall-clock NOW.
            self.elapsed = liveElapsedSeconds(now: Date())

            // If we already crossed the cutoff while the app was gone,
            // immediately finalize and notify so it writes to HealthKit.
            if shouldAutoEnd(now: Date(), start: saved) {
                endAndNotify(reason: "rescue-after-cutoff")
                return
            }

            startTicker()
            startMotionMonitoring()
        } else {
            // No active session
            self.isRunning = false
            self.startDate = nil
            self.elapsed = 0
            stopTicker()
            motionGuard.stopMonitoring()
        }
    }

    // MARK: - WINDOW CHECK (unchanged)
    var isWithinAllowedWindow: Bool {
        let now = Date()
        let h = Calendar.current.component(.hour, from: now)
        return (h >= 20) || (h < cutoffHour)
    }

    // MARK: - LIVE ELAPSED CALC
    /// Source of truth: wall clock time since startDate.
    /// This fixes the "stale elapsed while phone was off" problem.
    private func liveElapsedSeconds(now: Date = Date()) -> TimeInterval {
        guard isRunning, let s = startDate else { return elapsed }
        return now.timeIntervalSince(s)
    }

    var elapsedStringMono: String {
        // Use liveElapsedSeconds(), not the last ticked `elapsed`.
        let total = Int(max(0, liveElapsedSeconds()))
        let hh = total / 3600
        let mm = (total % 3600) / 60
        let ss = (total % 60)
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }

    // MARK: - CONTROLS
    func start() {
        guard !isRunning else { return }
        let now = Date()
        self.startDate = now
        self.isRunning = true
        self.elapsed = 0

        persistRunning(true, start: now)
        startTicker()
        startMotionMonitoring()
    }

    /// Unified "we're done" path. We ALWAYS calculate the real end
    /// using wall clock, even if the app's been backgrounded for hours.
    /// After we end, we call onAutoEnded(start, effectiveEnd)
    /// so the caller writes to HealthKit once.
    func endAndNotify(reason: String = "manual") {
        guard let result = endNowInternal() else { return }

        // We ALWAYS notify so Health gets the true span.
        // Upstream can choose how to treat <30 min for points.
        self.onAutoEnded?(result.start, result.effectiveEnd)
    }

    /// Low-level "end now and return info", used by endAndNotify().
    /// NOTE: This is now private. Call endAndNotify() from the UI.
    @discardableResult
    private func endNowInternal()
    -> (start: Date, rawEnd: Date, effectiveEnd: Date, seconds: TimeInterval)?
    {
        guard let start = self.startDate else { return nil }

        // CRITICAL FIX:
        // Don't trust the most recent `elapsed` snapshot.
        // Compute end based on wall clock NOW.
        let rawEnd = Date()

        // Clamp to cutoff (still honoring your noon rule / Fri+Sat no-cutoff logic).
        let effectiveEnd = min(rawEnd, cutoffDate(for: start))

        let seconds = max(0, effectiveEnd.timeIntervalSince(start))

        // Update elapsed once more so UI / debug shows final length
        self.elapsed = seconds

        // Tear down session
        self.isRunning = false
        self.startDate = nil
        persistRunning(false, start: nil)
        stopTicker()
        motionGuard.stopMonitoring()

        return (start, rawEnd, effectiveEnd, seconds)
    }

    /// If we want to silently kill a session without notifying/writing.
    func abandon() {
        _ = endNowInternal()
    }

    // MARK: - APP LIFECYCLE HOOKS
    func appDidEnterBackground() {
        // We can't keep a 1/sec ticker running in background forever anyway.
        stopTicker()
    }

    func appWillEnterForeground() {
        guard isRunning, let _ = startDate else { return }

        // Immediately snap `elapsed` to the real wall-clock gap
        // BEFORE user hits "End Session".
        // This erases the "jump from 2min to 8hr on stop" glitch.
        self.elapsed = liveElapsedSeconds(now: Date())

        // If cutoff passed while we were backgrounded, finalize right now.
        if shouldAutoEnd(now: Date(), start: self.startDate!) {
            endAndNotify(reason: "foreground-cutoff")
            return
        }

        // Resume ticker for the live on-screen countdown.
        startTicker()
    }

    // MARK: - CUTOFF LOGIC (unchanged behavior)
    /// Friday/Saturday nights have **no cutoff**.
    /// We treat "night" based on Apple's noon-boundary convention.
    private func nightWeekday(for start: Date) -> Int {
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: start)!
        let nightDate = (start < noon)
            ? cal.date(byAdding: .day, value: -1, to: noon)!
            : noon
        return cal.component(.weekday, from: nightDate) // 1=Sun ... 6=Fri, 7=Sat
    }

    private func isNoCutoffNight(_ start: Date) -> Bool {
        let wd = nightWeekday(for: start)
        return (wd == 6 || wd == 7) // Fri or Sat night → no cutoff
    }

    private func cutoffDate(for start: Date) -> Date {
        if isNoCutoffNight(start) {
            return .distantFuture // never clamp on Fri/Sat nights
        }
        let cal = Calendar.current
        let startHour = cal.component(.hour, from: start)
        // If you went to bed before noon, that "night" belongs to *previous* date bucket.
        let base = (startHour < cutoffHour)
            ? start
            : cal.date(byAdding: .day, value: 1, to: start)!
        // Clamp at 12:00 PM of that bucket
        return cal.date(bySettingHour: cutoffHour, minute: 0, second: 0, of: base)!
    }

    private func shouldAutoEnd(now: Date, start: Date) -> Bool {
        now >= cutoffDate(for: start)
    }

    // MARK: - TICKER & PERSISTENCE
    private func startTicker() {
        stopTicker()
        ticker = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      self.isRunning,
                      let _ = self.startDate else { return }

                // Each tick, recompute from wall clock, not incremental drift.
                self.elapsed = self.liveElapsedSeconds(now: Date())

                // If we quietly crossed cutoff while foregrounded, auto end.
                if self.shouldAutoEnd(now: Date(), start: self.startDate!) {
                    self.endAndNotify(reason: "auto-cutoff")
                }
            }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func persistRunning(_ running: Bool, start: Date?) {
        let ud = UserDefaults.standard
        ud.set(running, forKey: kIsRunning)
        if let start {
            ud.set(start, forKey: kStartDate)
        } else {
            ud.removeObject(forKey: kStartDate)
        }
    }

    // MARK: - MOTION GUARD
    private func startMotionMonitoring() {
        motionGuard.startMonitoring(
            config: MotionGuard.Config(
                spikeThresholdG: 1.05,
                minSpikeCount: 4,
                horizonSeconds: 10,
                updateHz: 40,
                armingDelaySeconds: 10,
                debugLogging: false
            ),
            onViolation: { [weak self] in
                guard let self = self, self.isRunning else { return }
                // Treat a violation as the final end.
                // IMPORTANT: This will now use wall-clock to compute the end,
                // so if the phone was off for 8 hours and only now moved,
                // we record the FULL 8 hours instead of a bogus 2 minutes.
                self.endAndNotify(reason: "motion-violation")
            }
        )
    }
}
