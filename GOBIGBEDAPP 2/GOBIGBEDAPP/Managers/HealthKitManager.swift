import Foundation
import HealthKit
import Combine

final class HealthKitManager: ObservableObject {


    @Published private(set) var hasSleepAccess: Bool = false


    let healthStore = HKHealthStore()

  

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable(),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        else { completion(false); return }

        let readTypes: Set<HKObjectType> = [sleepType]
        let writeTypes: Set<HKSampleType> = [sleepType]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, _ in
            self?.refreshAuthorizationStatus()
            DispatchQueue.main.async { completion(success) }
        }
    }

    func refreshAuthorizationStatus() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            DispatchQueue.main.async { self.hasSleepAccess = false }
            return
        }
        let canRead = healthStore.authorizationStatus(for: sleepType) != .notDetermined
        let canShare = healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
        DispatchQueue.main.async { self.hasSleepAccess = (canRead || canShare) }
    }


    func writeSleep(start: Date, end: Date, completion: @escaping (Bool) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false); return
        }
        
        let value = HKCategoryValueSleepAnalysis.asleep.rawValue
        let sample = HKCategorySample(type: sleepType, value: value, start: start, end: end)
        healthStore.save(sample) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    func fetchDailyHours(startDate: Date, endDate: Date, completion: @escaping ([(Date, Double)]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([]); return
        }
        let cal = Calendar.current

        
        func healthDayStart(for date: Date) -> Date {
            let noonToday = cal.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
            return (date < noonToday) ? cal.date(byAdding: .day, value: -1, to: noonToday)! : noonToday
        }


        let bucketStart = healthDayStart(for: startDate)
        let lastBucketStart = healthDayStart(for: endDate)
        var bucketStarts: [Date] = []
        var d = bucketStart
        while d <= lastBucketStart {
            bucketStarts.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        guard !bucketStarts.isEmpty else { completion([]); return }


        let queryStart = bucketStart
        let queryEnd = cal.date(byAdding: .day, value: 1, to: lastBucketStart)!

        let datePredicate = HKQuery.predicateForSamples(
            withStart: queryStart,
            end: queryEnd,
            options: [.strictStartDate, .strictEndDate]
        )


        let mySource = HKSource.default()
        let sourcePredicate = HKQuery.predicateForObjects(from: [mySource])

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, sourcePredicate])

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard self != nil, let samples = samples as? [HKCategorySample] else {
                DispatchQueue.main.async { completion([]) }
                return
            }


            let notUserEntered: [HKCategorySample] = samples.filter { smp in
                if let wasUserEntered = smp.metadata?[HKMetadataKeyWasUserEntered] as? Bool, wasUserEntered {
                    return false
                }
                return true
            }


            let asleepValues: Set<Int> = {
                var s: Set<Int> = [HKCategoryValueSleepAnalysis.asleep.rawValue]
                if #available(iOS 16.0, *) {
                    s.formUnion([
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    ])
                }
                return s
            }()


            var intervals: [(Date, Date)] = []
            for smp in notUserEntered where asleepValues.contains(smp.value) {
                let s = max(smp.startDate, queryStart)
                let e = min(smp.endDate, queryEnd)
                if s < e { intervals.append((s, e)) }
            }
            intervals.sort { $0.0 < $1.0 }


            var merged: [(Date, Date)] = []
            for iv in intervals {
                if let last = merged.last, iv.0 <= last.1 {
                    merged[merged.count - 1].1 = max(last.1, iv.1)
                } else {
                    merged.append(iv)
                }
            }


            var totals: [Date: TimeInterval] = [:]
            for s in bucketStarts { totals[s] = 0 }

            for (segStart0, segEnd0) in merged {
                var segStart = segStart0
                let segEnd = segEnd0
                while segStart < segEnd {
                    let bStart = healthDayStart(for: segStart)
                    let bEnd = cal.date(byAdding: .day, value: 1, to: bStart)!
                    let clippedEnd = min(segEnd, bEnd)
                    let overlap = clippedEnd.timeIntervalSince(segStart)
                    if overlap > 0 {
                        totals[bStart, default: 0] += overlap
                    }
                    segStart = clippedEnd
                }
            }


            let result: [(Date, Double)] = bucketStarts.map { start in
                (start, (totals[start] ?? 0) / 3600.0)
            }

            DispatchQueue.main.async { completion(result) }
        }

        healthStore.execute(q)
    }

    

    func fetchLastDays(_ days: Int, completion: @escaping ([(Date, Double)]) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -(days - 1), to: now) ?? now
        fetchDailyHours(startDate: start, endDate: now, completion: completion)
    }
}
