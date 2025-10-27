import SwiftUI
import Combine
import Charts

struct SleepView: View {
    @EnvironmentObject var appState: AppState

    @State private var lastUpdated: Date = Date()
    @State private var lastRecordedHours: Double = 0
    @State private var lastRecordedPoints: Int = 0

    @State private var weekPoints: [Point] = []

    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Last Updated: \(formatted(lastUpdated))")
                    .foregroundColor(Theme.textMuted)


                VStack(alignment: .leading, spacing: 10) {
                    Text("Last Recorded Night of Sleep")
                        .font(.headline)
                        .foregroundColor(Theme.text)

                    Text("\(lastRecordedHours, specifier: "%.1f") hrs")
                        .font(.system(size: 76, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                        .allowsTightening(true)

                    Text("Points earned: \(lastRecordedPoints)")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()


                ZStack {
                    Theme.card.cornerRadius(18)

                    Chart(weekPoints) { p in
                        LineMark(
                            x: .value("Day", p.date, unit: .day),
                            y: .value("Hours", p.hours)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Theme.red)

                        PointMark(
                            x: .value("Day", p.date, unit: .day),
                            y: .value("Hours", p.hours)
                        )
                        .foregroundStyle(Theme.red)
                    }
                    .chartPlotStyle { $0.background(.clear) }
                    .chartYScale(domain: 0...20)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }

                    .overlay(
                        Chart {
                            RuleMark(y: .value("Goal", 8))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 6]))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .chartYScale(domain: 0...20)
                        .chartPlotStyle { $0.background(.clear) }
                        .allowsHitTesting(false)
                    )
                    .padding(12)
                }
                .frame(height: 320)


                let totalHours = weekPoints.reduce(0) { $0 + $1.hours }
                Text("Hours Slept in The Past 7 Days: \(totalHours, specifier: "%.1f") hrs")
                    .foregroundColor(Theme.text)
                    .padding(.top, 8)

                Button(action: refresh) {
                    Text("Refresh Sleep Data")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Theme.black.ignoresSafeArea())
        .onAppear { refresh() }
       
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refresh()
        }
    }


    private func refresh() {
        lastUpdated = Date()

        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -6, to: now) ?? now

        appState.healthManager.fetchDailyHours(startDate: start, endDate: now) { days in

            let included = days.filter { $0.1 > 0 }


            let mapped: [Point] = included.map { (bucketStart, hours) in
                let displayDate = cal.date(byAdding: .day, value: 1, to: bucketStart) ?? bucketStart
                return Point(date: displayDate, hours: hours)
            }
            self.weekPoints = mapped


            if let last = mapped.last {
                lastRecordedHours = max(0, last.hours)
            } else {
                lastRecordedHours = 0
            }
            lastRecordedPoints = Int(round(lastRecordedHours * 10.0))
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
