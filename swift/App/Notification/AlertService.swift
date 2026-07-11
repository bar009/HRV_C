// Track D -- local notifications (Deep Dive 6). Mac-only.
// Wording is deliberately wellness-only (OP-1): a gentle observation, never a
// medical claim like "there is a problem with your heart".
#if canImport(UserNotifications)
import Foundation
import UserNotifications
import HRVCore

final class AlertService {
    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func fireHRVDrop(_ event: AlertEvent) {
        let content = UNMutableNotificationContent()
        content.title = "שינוי בדפוסי המנוחה שלך"
        content.body = "שמנו לב לירידה בדפוס ה-HRV שלך לאחרונה. אולי כדאי לקחת רגע לנוח."
        content.sound = .default
        // Local only -- no server, no push. Fires immediately (trigger: nil).
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
#endif
