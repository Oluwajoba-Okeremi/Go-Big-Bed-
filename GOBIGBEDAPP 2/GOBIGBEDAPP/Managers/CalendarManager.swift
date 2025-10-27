import Foundation
import EventKit
import UIKit


final class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()

    @Published var authorized: Bool = false
    @Published var lastActionMessage: String? = nil

    init() {
        refreshAuthorization()
    }

    
    func requestAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)

        if status == .notDetermined {
            if #available(iOS 17.0, *) {
                eventStore.requestFullAccessToEvents { granted, _ in
                    DispatchQueue.main.async {
                        self.authorized = granted
                        self.lastActionMessage = granted ? "Calendar access granted." : "Calendar access denied."
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    DispatchQueue.main.async {
                        self.authorized = granted
                        self.lastActionMessage = granted ? "Calendar access granted." : "Calendar access denied."
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.authorized = self.isAuthorizedNow()
                self.lastActionMessage = self.authorized ? "Calendar already authorized." : "Calendar not authorized."
            }
        }
    }

 
    func refreshAuthorization() {
        DispatchQueue.main.async {
            self.authorized = self.isAuthorizedNow()
        }
    }


    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }


    func scheduleWorkReminder(for date: Date) {
        guard authorized else {
            lastActionMessage = "Calendar not authorized."
            return
        }
        guard let targetCalendar = eventStore.defaultCalendarForNewEvents else {
            lastActionMessage = "No default calendar available."
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "Focus Session"
        event.startDate = date
        event.endDate = date.addingTimeInterval(30 * 60)
        event.calendar = targetCalendar

        do {
            try eventStore.save(event, span: .thisEvent)
            lastActionMessage = "Event saved for \(date.formatted(date: .abbreviated, time: .shortened))."
        } catch {
            lastActionMessage = "Failed to save event: \(error.localizedDescription)"
        }
    }

    private func isAuthorizedNow() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .authorized || status == .fullAccess
        } else {
            return status == .authorized
        }
    }
}
