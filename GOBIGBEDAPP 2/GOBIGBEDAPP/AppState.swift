import SwiftUI

final class AppState: ObservableObject {

    @Published var healthManager   = HealthKitManager()
    @Published var rewardManager   = RewardManager()
    @Published var calendarManager = CalendarManager()
    @Published var authManager     = AuthManager()
    

    @Published var notificationManager = NotificationManager()
    

    @AppStorage("installationDateISO") private var installationDateISO: String?

    var installationDate: Date? {
        get {
            guard let s = installationDateISO else { return nil }
            return ISO8601DateFormatter().date(from: s)
        }
        set {
            installationDateISO = newValue.map { ISO8601DateFormatter().string(from: $0) }
        }
    }
}
