import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {

            SleepView()
                .tabItem { Label("Sleep Data", systemImage: "bed.double.fill") }


            SleepTrackingView()
                .tabItem { Label("Sleep Tracking", systemImage: "stopwatch") }

           
            RewardsView()
                .tabItem { Label("Rewards", systemImage: "star.circle.fill") }

            
            MotivationView()
                .tabItem { Label("Motivation", systemImage: "bolt.heart") }

            
            InstructionsView()
                .tabItem { Label("Instructions", systemImage: "list.bullet.rectangle") }
        }
        .tint(Theme.red)
        .background(Theme.black.ignoresSafeArea())
    }
}
