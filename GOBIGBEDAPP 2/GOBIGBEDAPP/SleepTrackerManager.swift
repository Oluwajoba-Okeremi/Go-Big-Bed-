import Foundation
import HealthKit
import Combine

final class SleepTrackerManager: ObservableObject {

    @Published private(set) var isTracking: Bool = false
    @Published private(set) var trackingStart: Date? = nil
    @Published private(set) var lastSavedRange: (start: Date, end: Date)? = nil
    @Published private(set) var lastSaveError: String? = nil

    private let healthStore = HKHealthStore()
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let startKey = "sleeptracker_start_iso"

    init() {
        if let iso = UserDefaults.standard.string(forKey: startKey),
           let date = ISO8601DateFormatter().date(from: iso) {
            trackingStart = date
            isTracking = true
        }
        // Runtime sanity check: prints what the app *actually* sees.
        if let share = Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") as? String {
            print("ℹ️ NSHealthShareUsageDescription:", share)
        } else {
            print("⚠️ NSHealthShareUsageDescription MISSING at runtime")
        }
        if let update = Bundle.main.object(forInfoDictionaryKey: "NSHealthUpdateUsageDescription") as? String {
            print("ℹ️ NSHealthUpdateUsageDescription:", update)
        } else {
            print("⚠️ NSHealthUpdateUsageDescription MISSING at runtime")
        }
    }

    // MARK: - Permissions

    /// Non-crashing authorization: requests READ always; WRITE only if the
    /// Update Usage string is present in the running binary.
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false); return }

        let readTypes: Set<HKObjectType>  = [sleepType]
        let writeTypes: Set<HKSampleType> = hasUpdateUsageString() ? [sleepType] : []

        if writeTypes.isEmpty {
            print("⚠️ Missing NSHealthUpdateUsageDescription at runtime; requesting READ-only.")
            self.lastSaveError = "Health write reason string missing; write disabled."
        }

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            DispatchQueue.main.async {
                if let error = error { print("❌ HK auth error:", error.localizedDescription) }
                completion(success)
            }
        }
    }

    // MARK: - Start / Stop

    func startTracking() {
        requestAuthorizationIfNeeded { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.lastSaveError = "Health permission not granted."
                return
            }
            let now = Date()
            self.trackingStart = now
            self.isTracking = true
            UserDefaults.standard.set(ISO8601DateFormatter().string(from: now), forKey: self.startKey)
        }
    }

    func stopTracking() {
        guard let start = trackingStart else { return }
        let end = Date()

        // If write isn’t authorized (or update string missing), do NOT crash—show message.
        let status = healthStore.authorizationStatus(for: sleepType)
        if status != .sharingAuthorized || !hasUpdateUsageString() {
            self.lastSaveError = "Cannot save to Health: write not authorized (or usage string missing)."
            self.isTracking = false
            self.trackingStart = nil
            UserDefaults.standard.removeObject(forKey: startKey)
            return
        }

        writeSleepSample(start: start, end: end) { [weak self] ok, errorText in
            guard let self = self else { return }
            if ok {
                self.lastSavedRange = (start, end)
                self.lastSaveError = nil
            } else {
                self.lastSaveError = errorText ?? "Unknown error saving to Health."
            }
            self.trackingStart = nil
            self.isTracking = false
            UserDefaults.standard.removeObject(forKey: self.startKey)
        }
    }

    // MARK: - Write

    private func writeSleepSample(start: Date, end: Date, completion: @escaping (Bool, String?) -> Void) {
        let value: Int
        if #available(iOS 16.0, *) {
            value = HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        } else {
            value = HKCategoryValueSleepAnalysis.asleep.rawValue
        }
        let sample = HKCategorySample(type: sleepType, value: value, start: start, end: end, metadata: [
            HKMetadataKeyFoodType: "GoBigBedApp sleep session"
        ])
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error?.localizedDescription)
                if success {
                    print("✅ Saved sleepAnalysis \(start) → \(end) to Health.")
                } else {
                    print("❌ Save failed:", error?.localizedDescription ?? "Unknown")
                }
            }
        }
    }

    // MARK: - Helpers

    private func hasUpdateUsageString() -> Bool {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "NSHealthUpdateUsageDescription") as? String
        else { return false }
        return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func elapsedString(now: Date = Date()) -> String {
        guard let start = trackingStart else { return "00:00:00" }
        let t = Int(now.timeIntervalSince(start))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
