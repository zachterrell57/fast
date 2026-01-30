//
//  FastSummaryView.swift
//  Fast
//
//  Summary view displayed when a fast is complete or viewing past fasts.
//

import SwiftUI

struct FastSummaryView: View {
    let session: FastSession
    let isToday: Bool
    let onStartNewFast: (() -> Void)?

    @State private var editingStartTime = false
    @State private var editingEndTime = false
    @State private var editDate = Date()

    private let calendar = Calendar.current

    private var completionPercentage: Double? {
        guard let target = session.targetDuration, target > 0 else { return nil }
        return session.elapsedDuration / target
    }

    private var progress: CGFloat {
        // Cap at 1.0 for the ring
        // For no-goal sessions, show full ring
        guard let percentage = completionPercentage else { return 1.0 }
        return min(1.0, CGFloat(percentage))
    }

    private var formattedDuration: String {
        let totalSeconds = Int(session.elapsedDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private var formattedTargetDuration: String? {
        guard let target = session.targetDuration else { return nil }
        let totalSeconds = Int(target)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.startAt)
    }

    private var endTimeFormatted: String {
        guard let endAt = session.endAt else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: endAt)
    }

    private var percentageText: String? {
        guard let percentage = completionPercentage else { return nil }
        return "\(Int(percentage * 100))%"
    }

    private var goalReached: Bool {
        guard let percentage = completionPercentage else {
            // No goal = always show checkmark (user completed by choice)
            return true
        }
        return percentage >= 1.0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Circular progress ring with completion
            TimerRing(progress: progress) {
                // Center content
                VStack(spacing: 4) {
                    // Checkmark for completed fasts
                    if goalReached {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    // Duration
                    Text(formattedDuration)
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .monospacedDigit()

                    // Percentage (only if goal was set)
                    if let percentage = percentageText {
                        Text(percentage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Bottom content - fixed height for consistent layout
            VStack(spacing: 8) {
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("Started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(startTimeFormatted)
                            .font(.subheadline.weight(.medium))
                            .underline(color: .secondary.opacity(0.5))
                    }
                    .onTapGesture {
                        editDate = session.startAt
                        editingStartTime = true
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)

                    VStack(spacing: 2) {
                        Text("Ended")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(endTimeFormatted)
                            .font(.subheadline.weight(.medium))
                            .underline(color: .secondary.opacity(0.5))
                    }
                    .onTapGesture {
                        if let endAt = session.endAt {
                            editDate = endAt
                            editingEndTime = true
                        }
                    }
                }

                // Goal info (only if goal was set)
                if let targetDuration = formattedTargetDuration {
                    Text("Goal: \(targetDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Start New Fast button (only for today)
                if isToday, let onStartNewFast = onStartNewFast {
                    Button {
                        onStartNewFast()
                    } label: {
                        Label("Start New Fast", systemImage: "play.fill")
                            .font(.headline)
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .frame(height: 120)
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $editingStartTime) {
            TimeEditSheet(
                editType: .start,
                date: $editDate,
                maxDate: session.endAt,
                onSave: { newDate in
                    session.startAt = newDate
                }
            )
        }
        .sheet(isPresented: $editingEndTime) {
            TimeEditSheet(
                editType: .end,
                date: $editDate,
                minDate: session.startAt,
                maxDate: Date(),
                onSave: { newDate in
                    session.endAt = newDate
                }
            )
        }
    }
}

#Preview("Goal Reached") {
    let session = FastSession(
        startAt: Calendar.current.date(byAdding: .hour, value: -17, to: Date())!,
        targetDuration: 16 * 3600
    )
    session.endAt = Calendar.current.date(byAdding: .hour, value: -1, to: Date())

    return FastSummaryView(session: session, isToday: true) {
        print("Start new fast")
    }
}

#Preview("Ended Early") {
    let session = FastSession(
        startAt: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
        targetDuration: 16 * 3600
    )
    session.endAt = Calendar.current.date(byAdding: .hour, value: -4, to: Date())

    return FastSummaryView(session: session, isToday: false, onStartNewFast: nil)
}

#Preview("Open Ended Fast") {
    let session = FastSession(
        startAt: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
        targetDuration: nil
    )
    session.endAt = Calendar.current.date(byAdding: .hour, value: -1, to: Date())

    return FastSummaryView(session: session, isToday: true) {
        print("Start new fast")
    }
}
