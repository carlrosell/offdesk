import Foundation
import UserNotifications

/// Posts a local notification after a clean. Authorization is requested once at
/// launch; if denied, `notifyCleaned` is simply a no-op.
final class Notifier {
    static let shared = Notifier()
    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { NSLog("Clean: notification authorization failed: \(error.localizedDescription)") }
        }
    }

    func notifyCleaned(count: Int, destination: String) {
        guard count > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = "Desktop cleaned"
            content.body = count == 1 ? "Moved 1 item." : "Moved \(count) items."
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}
