import SwiftUI
import Charts

struct GraphsView: View {
    let days: [SleepDay]   
    var body: some View {
        Chart(days) { d in
            LineMark(x: .value("Day", d.date.shortWeekday),
                     y: .value("Hours", d.hours))
            PointMark(x: .value("Day", d.date.shortWeekday),
                      y: .value("Hours", d.hours))
        }
        .chartYScale(domain: 0...20)
        .frame(height: 260)
    }
}
