import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendReminder(minutes: Int, playSound: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = "SitWatcher"
        content.body = L10n.fmt("notification.body_fmt", minutes)
        content.sound = playSound ? .default : nil

        let request = UNNotificationRequest(
            identifier: "sit-reminder-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func clearAll() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
