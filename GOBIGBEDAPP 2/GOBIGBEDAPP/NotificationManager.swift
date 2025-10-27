import Foundation
import UserNotifications

/// Local notifications used by the app.
/// - Ask permission once
/// - Schedule a one-off 8pm "Evening Summary" for *today* (or tomorrow if 8pm passed)
/// - Schedule a repeating 11pm "Winding Down?" reminder
/// - Fire an immediate "credit earned" alert when credits increase
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    // UserDefaults keys (small + safe to keep here)
    private let lastCreditNotifiedKey = "notif.lastCreditNotified"

    // MARK: - Permission

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification permission error:", error.localizedDescription)
            } else {
                print(granted ? "✅ Notifications authorized" : "🚫 Notifications denied")
            }
        }
    }

    // MARK: - Evening summary (8pm, *non-repeating*)
    // Call this after you refresh HealthKit + points each day.
    func scheduleEveningSummary(hours: Double, points: Int) {
        let center = UNUserNotificationCenter.current()
        let id = "evening.summary"

        // Replace any existing "evening.summary" so the content reflects latest numbers
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Good Evening!"
        content.body  = "Last night you slept for \(String(format: "%.1f", hours)) hours, and got \(points) points."
        content.sound = .default

        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 20
        comps.minute = 0

        // If 8pm today has already passed, schedule for tomorrow
        let fireDate = cal.date(from: comps) ?? Date()
        let finalDate = (fireDate > Date()) ? fireDate : cal.date(byAdding: .day, value: 1, to: fireDate)!

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error { print("❌ scheduleEveningSummary error:", error.localizedDescription) }
        }
    }

    // MARK: - 11pm daily "Winding Down?"
    func ensureWindDownDaily() {
        let id = "winddown.daily"
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Winding Down?"
        content.body  = "A good night starts before midnight. Take 5 minutes to get ready for bed."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 23
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error { print("❌ ensureWindDownDaily error:", error.localizedDescription) }
        }
    }

    // MARK: - Credits (immediate)
    /// Call whenever you compute the *current* credit count.
    /// It will only notify if the count increased since the last notification.
    func handleCreditCount(_ currentCredits: Int) {
        let last = UserDefaults.standard.integer(forKey: lastCreditNotifiedKey)
        guard currentCredits > last else { return }
        notifyCreditEarned(increase: currentCredits - last)
        UserDefaults.standard.set(currentCredits, forKey: lastCreditNotifiedKey)
    }

    private func notifyCreditEarned(increase: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!"
        content.body  = "You've gotten a credit! Show it to your School to receive a Reward!"
        content.sound = .default

        // fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("❌ credit notification error:", error.localizedDescription) }
        }
    }

    // Foreground delivery (optional: show alerts while using the app)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
