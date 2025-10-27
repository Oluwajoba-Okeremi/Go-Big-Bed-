import SwiftUI
import Combine

struct RewardsView: View {
    @EnvironmentObject var appState: AppState

    
    @State private var totalPoints: Int = 0
    @State private var daily: [(Date, Int)] = []
    @State private var allDays: [(Date, Int)] = []
    @State private var lastRefreshed = Date()
    @State private var showAll = false

    
    private let recentInlineCount: Int = 3

    
    private let milestoneCap: Int = 7_890

    
    private var credits: Int {
        milestoneCap == 0 ? 0 : (totalPoints / milestoneCap)
    }

    
    private var progress: Double {
        guard milestoneCap > 0 else { return 0 }
        let remainder = totalPoints % milestoneCap
        return Double(remainder) / Double(milestoneCap)
    }

    
    private var fixedStartOct6_2025Noon: Date {
        var comps = DateComponents()
        comps.year = 2025; comps.month = 10; comps.day = 6
        comps.hour = 12; comps.minute = 0; comps.second = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    
    private var displayedDaily: ArraySlice<(Date, Int)> {
        daily.prefix(recentInlineCount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Total Points")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.text)

                    Text("\(formatInt(totalPoints))")
                        .font(.system(size: 76, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                        .allowsTightening(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Milestone Progress")
                            .font(.title3.weight(.bold))
                            .foregroundColor(Theme.text)
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "seal.fill").foregroundColor(Theme.red)
                            Text("Credits: \(credits)")
                                .font(.headline)
                                .foregroundColor(Theme.red)
                        }
                    }

                    MilestoneBar(progress: progress)
                        .frame(height: 22)

                    HStack {
                        Text("This cycle").foregroundColor(Theme.textMuted)
                        Spacer()
                        Text("\(formatInt(totalPoints % milestoneCap))/\(formatInt(milestoneCap))")
                            .foregroundColor(Theme.textMuted)
                    }
                    .font(.body)
                }
                .card()

                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Breakdown")
                            .font(.headline)
                            .foregroundColor(Theme.text)
                        Spacer()
                        if allDays.count > recentInlineCount {
                            Button(action: { showAll = true }) {
                                Text("See All").foregroundColor(Theme.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if displayedDaily.isEmpty {
                        Text("No days to show yet.")
                            .foregroundColor(Theme.textMuted)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(displayedDaily), id: \.0) { (day, pts) in
                            HStack {
                                Text(dayFormatted(day)).foregroundColor(Theme.text)
                                Spacer()
                                Text("+\(formatInt(pts))").foregroundColor(Theme.red).bold()
                            }
                            .padding()
                            .background(Theme.card)
                            .cornerRadius(14)
                        }
                    }
                }

                Button(action: refresh) {
                    Text("Refresh Rewards").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Last refreshed: \(timeFormatted(lastRefreshed))")
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
        .background(Theme.black.ignoresSafeArea())
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refresh()
        }
        .sheet(isPresented: $showAll) {
            AllDaysSheet(allDaily: allDays)
        }
    }

    
    private func refresh() {
        lastRefreshed = Date()

        let cal = Calendar.current
        let now = Date()
        let start = fixedStartOct6_2025Noon

        appState.healthManager.fetchDailyHours(startDate: start, endDate: now) { days in
            
            var mapped: [(Date, Int)] = days.map { (bucketStart, hours) in
                let displayDate = cal.date(byAdding: .day, value: 1, to: bucketStart) ?? bucketStart
                return (displayDate, Int(round(hours * 10.0)))
            }
            .sorted { $0.0 > $1.0 }

            
            mapped = mapped.filter { $0.1 > 0 }

            self.allDays = mapped
            self.daily   = mapped
            self.totalPoints = mapped.reduce(0) { $0 + $1.1 }
        }
    }

    
    private func dayFormatted(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
    private func timeFormatted(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
    private func formatInt(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}


private struct AllDaysSheet: View {
    @Environment(\.dismiss) private var dismiss
    let allDaily: [(Date, Int)]

    var body: some View {
        NavigationView {
            List {
                ForEach(allDaily, id: \.0) { (day, pts) in
                    HStack {
                        Text(dayFormatted(day))
                        Spacer()
                        Text("+\(formatInt(pts))").foregroundColor(Theme.red).bold()
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.black)
            .navigationTitle("All Days")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func dayFormatted(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
    private func formatInt(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}


private struct MilestoneBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let fillWidth = max(0, min(progress, 1)) * width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Theme.red)
                    .frame(width: fillWidth)
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 2)
                    .position(x: width * 0.5, y: height / 2)
            }
        }
    }
}
