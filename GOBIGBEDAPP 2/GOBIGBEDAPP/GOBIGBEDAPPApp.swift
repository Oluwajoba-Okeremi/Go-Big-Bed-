import SwiftUI

@main
struct GoBigBedApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .onAppear {
                                    
                    notificationManager.requestAuthorization()
                    notificationManager.ensureWindDownDaily()
                                           
                                }
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

private struct RootTabs: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            SleepView()
                .tabItem { Image(systemName: "bed.double.fill"); Text("Sleep Data") }

            SleepTrackingView()
                .tabItem { Image(systemName: "stopwatch"); Text("Sleep Tracking") }

            RewardsView()
                .tabItem { Image(systemName: "star.fill"); Text("Rewards") }

            MotivationView()
                .tabItem { Image(systemName: "bolt.heart.fill"); Text("Motivation") }

            InstructionsView()
                .tabItem { Image(systemName: "list.bullet.rectangle.portrait.fill"); Text("Instructions") }
        }
        .tint(Theme.red)
        .background(Theme.black.ignoresSafeArea())
    }
}
