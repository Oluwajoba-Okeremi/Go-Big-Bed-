import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var rewardManager: RewardManager

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                Text("Name: \(authManager.userName ?? "Unknown")")
                Text("Installed: \(formattedDate(appState.installationDate ?? Date()))")

                Button("Sign Out", role: .destructive) {
                    authManager.signOut()   
                }
            }

            Section(header: Text("Points")) {
                Text("⭐️ Total Points: \(rewardManager.totalPoints)")
            }

            Section(header: Text("Calendar")) {
                Text(calendarManager.authorized ? "Access: Granted" : "Access: Not granted")
                    .foregroundColor(.secondary)

                if calendarManager.authorized {
                    Button("Find Free Time and Schedule Reminder") {
                        let date = Date().addingTimeInterval(5 * 60)
                        calendarManager.scheduleWorkReminder(for: date)
                        alertMessage = calendarManager.lastActionMessage ?? ""
                        showAlert = !alertMessage.isEmpty
                    }
                } else {
                    HStack {
                        Button("Grant Calendar Access") {
                            calendarManager.requestAccess()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                alertMessage = calendarManager.lastActionMessage ?? ""
                                showAlert = !alertMessage.isEmpty
                            }
                        }
                        Button("Open Settings") {
                            calendarManager.openSettings()
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear { calendarManager.refreshAuthorization() }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Calendar"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
