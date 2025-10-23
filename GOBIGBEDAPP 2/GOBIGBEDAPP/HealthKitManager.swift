//
//  HealthKitManager.swift
//  GOBIGBEDAPP
//
//  Created by Oluwajoba Okeremi on 10/15/25.
//


import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    private var sleepType: HKCategoryType { HKObjectType.categoryType(forIdentifier: .sleepAnalysis)! }

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false); return }
        store.requestAuthorization(toShare: [], read: [sleepType]) { ok, _ in completion(ok) }
    }

    /// Fetch last `daysBack` days and aggregate by **wake day** (sample endDate’s day).
    func fetch(daysBack: Int = 14, completion: @escaping (Result<[SleepDay], Error>) -> Void) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -daysBack + 1, to: today)!
        let end   = cal.date(byAdding: .day, value: 1, to: today)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
            if let error = error { completion(.failure(error)); return }
            let samples = (samples as? [HKCategorySample]) ?? []

            var bucket: [Date: TimeInterval] = [:]
            var d = start
            while d <= today { bucket[d] = 0; d = cal.date(byAdding: .day, value: 1, to: d)! }

            for s in samples {
                let v = s.value
                let asleep =
                    v == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    v == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    v == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                    v == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                guard asleep else { continue }

                // CREDIT ENTIRE SEGMENT TO THE **DAY OF WAKE-UP**
                let wakeDay = cal.startOfDay(for: s.endDate)
                if bucket[wakeDay] != nil {
                    bucket[wakeDay]! += s.endDate.timeIntervalSince(s.startDate)
                }
            }

            let days = bucket.keys.sorted().map { day in
                SleepDay(date: day, hours: ((bucket[day] ?? 0)/3600.0).rounded(to: 1))
            }
            completion(.success(days))
        }
        store.execute(q)
    }
}
