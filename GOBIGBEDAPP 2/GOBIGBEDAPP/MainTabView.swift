import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var rewardManager: RewardManager

    var body: some View {
        TabView {
            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "bed.double.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .badge(rewardManager.totalPoints > 0 ? rewardManager.totalPoints : nil)
        }
    }
}

