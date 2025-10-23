import Foundation

public struct SleepEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public var duration: TimeInterval { end.timeIntervalSince(start) }

    public init(id: UUID = UUID(), start: Date, end: Date) {
        self.id = id; self.start = start; self.end = end
    }
}

public struct SleepDay: Identifiable, Hashable, Codable {
    public let date: Date            
    public let hours: Double
    public var id: Date { date }
}

public extension Double {
    func rounded(to places: Int) -> Double {
        let p = pow(10.0, Double(places)); return (self * p).rounded() / p
    }
}

public extension Date {
    var startOfDayLocal: Date { Calendar.current.startOfDay(for: self) }
    var shortWeekday: String { let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: self) }
    var mdy: String { let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: self) }
    var timestampForFooter: String { let f = DateFormatter(); f.dateFormat = "MMM d, yyyy 'at' h:mm a"; return f.string(from: self) }
}
