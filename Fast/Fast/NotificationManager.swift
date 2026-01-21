//
//  NotificationManager.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let notificationId = "fastComplete"

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleFastComplete(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Fast Complete"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelFastComplete() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
