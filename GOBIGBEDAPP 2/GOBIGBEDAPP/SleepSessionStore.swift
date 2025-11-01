import Foundation
import Combine

final class SleepSessionStore: ObservableObject {
    var onAutoEnded: ((Date, Date) -> Void)?

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var startDate: Date?
    @Published private(set) var elapsed: TimeInterval = 0

    static let minSeconds: TimeInterval = 30 * 60
    private let tickInterval: TimeInterval = 1

    private let cutoffHour: Int = 12

    private let kStartDate = "sleeptrack.currentStart"
    private let kIsRunning = "sleeptrack.isRunning"

    private var ticker: AnyCancellable?
    private let motionGuard = MotionGuard()
    private let audioKeeper = BackgroundAudioKeeper()

    func bootstrap() {
        let ud = UserDefaults.standard
        if let saved = ud.object(forKey: kStartDate) as? Date,
           ud.bool(forKey: kIsRunning) == true {

            self.startDate = saved
            self.isRunning = true

            self.elapsed = liveElapsedSeconds(now: Date())

            if shouldAutoEnd(now: Date(), start: saved) {
                endAndNotify(reason: "rescue-after-cutoff")
                return
            }

            audioKeeper.start()
            startTicker()
            startMotionMonitoring()
        } else {
            self.isRunning = false
            self.startDate = nil
            self.elapsed = 0
            stopTicker()
            motionGuard.stopMonitoring()
            audioKeeper.stop()
        }
    }

    var isWithinAllowedWindow: Bool {
        let now = Date()
        let h = Calendar.current.component(.hour, from: now)
        return (h >= 20) || (h < cutoffHour)
    }

    private func liveElapsedSeconds(now: Date = Date()) -> TimeInterval {
        guard isRunning, let s = startDate else { return elapsed }
        return now.timeIntervalSince(s)
    }

    var elapsedStringMono: String {
        let total = Int(max(0, liveElapsedSeconds()))
        let hh = total / 3600
        let mm = (total % 3600) / 60
        let ss = (total % 60)
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }

    func start() {
        guard !isRunning else { return }
        let now = Date()
        self.startDate = now
        self.isRunning = true
        self.elapsed = 0

        persistRunning(true, start: now)
        audioKeeper.start()
        startTicker()
        startMotionMonitoring()
    }

    func endAndNotify(reason: String = "manual") {
        guard let result = endNowInternal() else { return }
        self.onAutoEnded?(result.start, result.effectiveEnd)
    }

    @discardableResult
    private func endNowInternal()
    -> (start: Date, rawEnd: Date, effectiveEnd: Date, seconds: TimeInterval)?
    {
        guard let start = self.startDate else { return nil }

        let rawEnd = Date()
        let effectiveEnd = min(rawEnd, cutoffDate(for: start))
        let seconds = max(0, effectiveEnd.timeIntervalSince(start))

        self.elapsed = seconds

        self.isRunning = false
        self.startDate = nil
        persistRunning(false, start: nil)
        stopTicker()
        motionGuard.stopMonitoring()
        audioKeeper.stop()

        return (start, rawEnd, effectiveEnd, seconds)
    }

    func abandon() {
        _ = endNowInternal()
        audioKeeper.stop()
    }

    
    func appDidEnterBackground() {
        stopTicker()
    }

    func appWillEnterForeground() {
        guard isRunning, let _ = startDate else { return }

        self.elapsed = liveElapsedSeconds(now: Date())

        if shouldAutoEnd(now: Date(), start: self.startDate!) {
            endAndNotify(reason: "foreground-cutoff")
            return
        }

        startTicker()
    }

    private func nightWeekday(for start: Date) -> Int {
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: start)!
        let nightDate = (start < noon)
            ? cal.date(byAdding: .day, value: -1, to: noon)!
            : noon
        return cal.component(.weekday, from: nightDate)
    }

    private func isNoCutoffNight(_ start: Date) -> Bool {
        let wd = nightWeekday(for: start)
        return (wd == 6 || wd == 7)
    }

    private func cutoffDate(for start: Date) -> Date {
        if isNoCutoffNight(start) {
            return .distantFuture
        }
        let cal = Calendar.current
        let startHour = cal.component(.hour, from: start)
        let base = (startHour < cutoffHour)
            ? start
            : cal.date(byAdding: .day, value: 1, to: start)!
        return cal.date(bySettingHour: cutoffHour, minute: 0, second: 0, of: base)!
    }

    private func shouldAutoEnd(now: Date, start: Date) -> Bool {
        now >= cutoffDate(for: start)
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      self.isRunning,
                      let _ = self.startDate else { return }

                self.elapsed = self.liveElapsedSeconds(now: Date())

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
                self.endAndNotify(reason: "motion-violation")
            }
        )
    }
}
