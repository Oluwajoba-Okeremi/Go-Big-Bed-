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

    
    func bootstrap() {
        let ud = UserDefaults.standard
        if let saved = ud.object(forKey: kStartDate) as? Date,
           ud.bool(forKey: kIsRunning) == true {
            self.startDate = saved
            self.isRunning = true
            self.elapsed = Date().timeIntervalSince(saved)
            startTicker()
            startMotionMonitoring()
        } else {
            self.isRunning = false
            self.startDate = nil
            self.elapsed = 0
            stopTicker()
            motionGuard.stopMonitoring()
        }
    }

    
    var isWithinAllowedWindow: Bool {
        let now = Date()
        let h = Calendar.current.component(.hour, from: now)
        
        return (h >= 20) || (h < cutoffHour)
    }

    
    var elapsedStringMono: String {
        let s = Int(max(0, elapsed))
        let hh = s / 3600, mm = (s % 3600) / 60, ss = s % 60
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }

    
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

    
    @discardableResult
    func endNow() -> (start: Date, end: Date, effectiveEnd: Date, seconds: TimeInterval)? {
        guard let start = self.startDate else { return nil }

        let rawEnd = Date()
        let effectiveEnd = min(rawEnd, cutoffDate(for: start))
        let seconds = max(0, effectiveEnd.timeIntervalSince(start))

        
        self.isRunning = false
        self.startDate = nil
        self.elapsed = 0
        persistRunning(false, start: nil)
        stopTicker()
        motionGuard.stopMonitoring()

        return (start, rawEnd, effectiveEnd, seconds)
    }

    func abandon() {
        _ = endNow()
    }

    func appDidEnterBackground() { stopTicker() }
    func appWillEnterForeground() {
        guard isRunning, let s = startDate else { return }
        elapsed = Date().timeIntervalSince(s)
        startTicker()
        
    }

    
    private func cutoffDate(for start: Date) -> Date {
        let cal = Calendar.current
        let startHour = cal.component(.hour, from: start)

        
        let base = (startHour < cutoffHour) ? start : cal.date(byAdding: .day, value: 1, to: start)!
        return cal.date(bySettingHour: cutoffHour, minute: 0, second: 0, of: base)!
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, let s = self.startDate else { return }
                let now = Date()
                self.elapsed = now.timeIntervalSince(s)

                
                if now >= self.cutoffDate(for: s) {
                    if let result = self.endNow() {
                        self.onAutoEnded?(result.start, result.effectiveEnd)
                    }
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
                _ = self.endNow() 
            }
        )
    }
}
