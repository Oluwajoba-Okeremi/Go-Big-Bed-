import Foundation

final class RewardManager: ObservableObject {
    func points(forHours hours: Double) -> Int {
        Int(round(hours * 10.0)) 
    }

    func totalPoints(for days: [(Date, Double)]) -> Int {
        days.reduce(0) { $0 + points(forHours: $1.1) }
    }
}
