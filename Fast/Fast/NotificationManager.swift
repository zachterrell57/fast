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
    private let hourlyReminderPrefix = "hourlyReminder_"

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

    func scheduleHourlyReminders(fromHour hour: Int, minute: Int) {
        cancelHourlyReminders()

        let center = UNUserNotificationCenter.current()
        var nextHour = hour + 1

        while nextHour <= 23 {
            let content = UNMutableNotificationContent()
            content.title = "Don't forget to start your fast"
            content.body = "Tap to begin fasting"
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = nextHour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "\(hourlyReminderPrefix)\(nextHour)",
                content: content,
                trigger: trigger
            )

            center.add(request)
            nextHour += 1
        }
    }

    func cancelHourlyReminders() {
        let identifiers = (0...23).map { "\(hourlyReminderPrefix)\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
