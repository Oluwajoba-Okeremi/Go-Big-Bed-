import Foundation
import CoreMotion

final class MotionGuard {
    private let motion = CMMotionManager()
    private let queue = OperationQueue()

    
    struct Config {

        var spikeThresholdG: Double = 1.05
        var minSpikeCount: Int = 4
        var horizonSeconds: TimeInterval = 10
        var updateHz: Double = 40
        var armingDelaySeconds: TimeInterval = 10
        var debugLogging: Bool = false
    }

    private var config = Config()
    private var spikes: [Date] = []
    private var onViolation: (() -> Void)?
    private var isMonitoring = false
    private var startTime: Date?

    func startMonitoring(config: Config = Config(), onViolation: @escaping () -> Void) {
        stopMonitoring()
        self.config = config
        self.onViolation = onViolation
        self.spikes.removeAll()
        self.isMonitoring = true
        self.startTime = Date()

        queue.qualityOfService = .userInitiated

        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / config.updateHz
            motion.startDeviceMotionUpdates(to: queue) { [weak self] dm, _ in
                guard let self, self.isMonitoring, let dm = dm else { return }
                self.handleAccelSample(x: dm.userAcceleration.x,
                                       y: dm.userAcceleration.y,
                                       z: dm.userAcceleration.z,
                                       source: "DM")
            }
        }


        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = 1.0 / config.updateHz
            motion.startAccelerometerUpdates(to: queue) { [weak self] acc, _ in
                guard let self, self.isMonitoring, let a = acc else { return }
                self.handleAccelSample(x: a.acceleration.x,
                                       y: a.acceleration.y,
                                       z: a.acceleration.z,
                                       source: "ACC")
            }
        }


        if !motion.isDeviceMotionAvailable && !motion.isAccelerometerAvailable {
            stopMonitoring()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        motion.stopDeviceMotionUpdates()
        motion.stopAccelerometerUpdates()
        spikes.removeAll()
        onViolation = nil
        startTime = nil
    }


    private func handleAccelSample(x: Double, y: Double, z: Double, source: String) {

        if let t0 = startTime, Date().timeIntervalSince(t0) < config.armingDelaySeconds { return }


        let mag = sqrt(x*x + y*y + z*z)

        if config.debugLogging {
            if mag >= max(0.05, config.spikeThresholdG * 0.6) {
                print("[MotionGuard][\(source)] mag=\(String(format: "%.3f", mag)) spikes=\(spikes.count)")
            }
        }

        if mag >= config.spikeThresholdG {
            recordSpikeAndCheck()
        }
    }

    private func recordSpikeAndCheck() {
        let now = Date()
        spikes.append(now)
        
        let cutoff = now.addingTimeInterval(-config.horizonSeconds)
        spikes.removeAll { $0 < cutoff }

        if spikes.count >= config.minSpikeCount {
            let cb = onViolation
            stopMonitoring()
            DispatchQueue.main.async { cb?() }
        }
    }
}
