import Foundation
import UserNotifications
import UIKit
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        
        center.delegate = self
    }

 
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
            if let err = err {
                print("🔔 Notification auth error:", err.localizedDescription)
            } else {
                print("🔔 Notification auth granted:", granted)
            }
            self.debugSettings()
        }
    }


    func ensureWindDownDaily() {
        removePending(with: "windDownDaily")

        var dc = DateComponents()
        dc.hour = 23
        dc.minute = 0
        dc.second = 0
        dc.timeZone = .current

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Winding Down?"
        content.body  = "A good night’s routine helps you reach 8 hours."
        content.sound = .default

        let req = UNNotificationRequest(identifier: "windDownDaily",
                                        content: content,
                                        trigger: trigger)
        center.add(req)

        debugDumpPending()
    }


    func scheduleCreditEarnedNow() {
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!"
        content.body  = "You've gotten a credit! Show it to your School to receive a Reward!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString,
                                        content: content,
                                        trigger: trigger)
        center.add(req)
    }


    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.banner, .sound, .list])
    }



    private func removePending(with id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func debugDumpPending() {
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map { $0.identifier }
            print("🔔 Pending requests:", ids)
        }
    }

    private func debugSettings() {
        center.getNotificationSettings { s in
            print("🔔 Settings → auth:\(s.authorizationStatus.rawValue) alert:\(s.alertSetting.rawValue) badge:\(s.badgeSetting.rawValue) sound:\(s.soundSetting.rawValue)")
        }
    }
}
