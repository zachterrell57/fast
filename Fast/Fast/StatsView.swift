//
//  StatsView.swift
//  Fast
//
//  Compact stats display showing total hours fasted and current streak.
//

import SwiftUI

struct StatsView: View {
    let completedSessions: [FastSession]

    private let calendar = Calendar.current

    /// Total hours fasted across all completed sessions
    private var totalHoursFasted: Int {
        let totalSeconds = completedSessions.reduce(0.0) { $0 + $1.elapsedDuration }
        return Int(totalSeconds / 3600)
    }

    /// Current streak: consecutive days with at least one completed fast, counting back from today
    private var currentStreak: Int {
        guard !completedSessions.isEmpty else { return 0 }

        // Get unique days that have completed fasts (using startAt date)
        var fastedDays = Set<DateComponents>()
        for session in completedSessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startAt)
            fastedDays.insert(components)
        }

        // Start from today and count backwards
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)

            if fastedDays.contains(components) {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else if streak == 0 {
                // If today doesn't have a fast, check if yesterday started a streak
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
                let yesterdayComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                if fastedDays.contains(yesterdayComponents) {
                    streak += 1
                    guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                        break
                    }
                    currentDate = dayBefore
                } else {
                    break
                }
            } else {
                // Streak broken
                break
            }
        }

        return streak
    }

    var body: some View {
        HStack(spacing: 12) {
            // Total hours fasted
            StatItem(
                value: "\(totalHoursFasted)h",
                label: "fasted"
            )

            // Current streak
            StatItem(
                value: "\(currentStreak)d",
                label: "streak"
            )
        }
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    StatsView(completedSessions: [])
}
