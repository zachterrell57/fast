//
//  SettingsView.swift
//  Fast
//
//  Created by Zachary Terrell on 2/10/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @Environment(\.dismiss) private var dismiss

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 20
                reminderMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Evening Reminder")
                            .font(.body.weight(.medium))
                        Text("Daily reminder to start your fast")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if reminderEnabled {
                    DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: reminderEnabled) { _, enabled in
                if enabled {
                    NotificationManager.shared.scheduleEveningReminder(
                        hour: reminderHour, minute: reminderMinute
                    )
                    NotificationManager.shared.scheduleHourlyReminders(
                        fromHour: reminderHour, minute: reminderMinute
                    )
                } else {
                    NotificationManager.shared.cancelEveningReminder()
                    NotificationManager.shared.cancelHourlyReminders()
                }
            }
            .onChange(of: reminderHour) { _, _ in
                guard reminderEnabled else { return }
                NotificationManager.shared.scheduleEveningReminder(
                    hour: reminderHour, minute: reminderMinute
                )
                NotificationManager.shared.scheduleHourlyReminders(
                    fromHour: reminderHour, minute: reminderMinute
                )
            }
            .onChange(of: reminderMinute) { _, _ in
                guard reminderEnabled else { return }
                NotificationManager.shared.scheduleEveningReminder(
                    hour: reminderHour, minute: reminderMinute
                )
                NotificationManager.shared.scheduleHourlyReminders(
                    fromHour: reminderHour, minute: reminderMinute
                )
            }
        }
        .presentationDetents([.medium])
    }
}
