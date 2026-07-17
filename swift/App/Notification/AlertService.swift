// Track D -- local notifications (Deep Dive 6). Mac-only.
// Wording is deliberately wellness-only (OP-1): a gentle observation, never a
// medical claim like "there is a problem with your heart".
#if canImport(UserNotifications)
import Foundation
import UserNotifications
import HRVCore

final class AlertService: NSObject, UNUserNotificationCenterDelegate {
    private static let eventIDKey = "eventID"

    /// UI_WIRING P3: a tapped alert routes to Attention -> Guided Moment.
    /// The coordinator injects this to receive the tapped event's id.
    var onOpenAlert: ((UUID?) -> Void)?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func fireHRVDrop(_ event: AlertEvent, eventID: UUID? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "שינוי בדפוסי המנוחה שלך"
        content.body = "שמנו לב לירידה בדפוס ה-HRV שלך לאחרונה. אולי כדאי לקחת רגע לנוח."
        content.sound = .default
        if let eventID { content.userInfo = [Self.eventIDKey: eventID.uuidString] }
        // Local only -- no server, no push. Fires immediately (trigger: nil).
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Show the banner even while the app is in the foreground -- otherwise a
    /// live alert is silently dropped when the user happens to be in the app.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let raw = response.notification.request.content.userInfo[Self.eventIDKey] as? String
        onOpenAlert?(raw.flatMap(UUID.init(uuidString:)))
    }
}
#endif
