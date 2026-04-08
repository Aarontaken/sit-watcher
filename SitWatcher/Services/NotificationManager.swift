import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendReminder(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "SitWatcher"
        content.body = "已经坐了 \(minutes) 分钟了，起来活动一下吧 💪"
        content.sound = .default

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
