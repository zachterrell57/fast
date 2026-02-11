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
    private let reminderId = "eveningReminder"

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

    func scheduleEveningReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to start your fast"
        content.body = "Tap to begin fasting"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: reminderId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelEveningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
    }
}
