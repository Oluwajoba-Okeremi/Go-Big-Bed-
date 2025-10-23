import SwiftUI

/// Shows the cumulative rewards earned and highlights potential incentives.
struct RewardsView: View {
    @EnvironmentObject var rewardManager: RewardManager  // observe live total

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Total Points").font(.title).bold()
            Text("\(rewardManager.totalPoints)")
                .font(.system(size: 48, weight: .heavy))
                .foregroundColor(.red)

            Divider()

            Text("Redeemable Rewards").font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                RewardRow(icon: "dollarsign.circle.fill",
                          title: "Dorm Funds",
                          description: "Use points toward housing or meal credits.")
                RewardRow(icon: "flame.fill",
                          title: "Fatigues",
                          description: "Earn fatigue passes for PE or drills.")
                RewardRow(icon: "fork.knife",
                          title: "Grill Points",
                          description: "Grab an extra snack at the campus grill.")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Rewards")
    }
}

private struct RewardRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .font(.title)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

