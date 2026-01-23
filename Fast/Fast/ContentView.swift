//
//  ContentView.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<FastSession> { $0.endAt == nil }) private var activeSessions: [FastSession]
    @Query(filter: #Predicate<FastSession> { $0.endAt != nil }) private var completedSessions: [FastSession]
    @StateObject private var timerEngine = TimerEngine()

    #if DEBUG
    @AppStorage("debugModeEnabled") private var debugModeEnabled = false
    @State private var titleTapCount = 0
    #endif

    private var fastingPresets: [(label: String, seconds: Int)] {
        var presets: [(label: String, seconds: Int)] = []
        #if DEBUG
        if debugModeEnabled {
            presets.append(("3s", 3))
        }
        #endif
        presets.append(contentsOf: [
            ("12h", 12 * 3600),
            ("16h", 16 * 3600),
            ("18h", 18 * 3600)
        ])
        return presets
    }

    @State private var selectedSeconds: Int = 0
    @State private var selectedPreset: Int? = nil
    @State private var lastDialHour: Int = 0
    @State private var selectedDate: Date? = nil  // nil = today, set to view past dates
    @State private var showingNewFastAfterSummary: Bool = false  // Force show dial after "Start New Fast"
    @State private var swipeOffset: CGFloat = 0  // Track horizontal swipe gesture
    private let maxDuration: TimeInterval = 24 * 3600 // 24 hours
    private let dialFeedback = UIImpactFeedbackGenerator(style: .light)
    private let swipeFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let calendar = Calendar.current
    private let swipeThreshold: CGFloat = 50  // Minimum swipe distance to trigger navigation

    private var activeSession: FastSession? {
        activeSessions.first
    }

    /// Session completed today (for showing summary after completion)
    /// Checks endAt instead of startAt to handle overnight fasts correctly
    private var todayCompletedSession: FastSession? {
        completedSessions
            .filter { session in
                guard let endAt = session.endAt else { return false }
                return calendar.isDateInToday(endAt)
            }
            .sorted { ($0.endAt ?? .distantPast) > ($1.endAt ?? .distantPast) }
            .first
    }

    /// Session for the selected date (when viewing past dates from calendar)
    /// Returns the most recent session if multiple fasts occurred on that day
    private var sessionForSelectedDate: FastSession? {
        guard let date = selectedDate else { return nil }
        return sessionFor(date: date)
    }

    /// Get session for any arbitrary date
    private func sessionFor(date: Date) -> FastSession? {
        return completedSessions
            .filter { calendar.isDate($0.startAt, inSameDayAs: date) }
            .sorted { $0.startAt > $1.startAt }
            .first
    }

    /// Whether we're viewing today or a past date
    private var isViewingToday: Bool {
        selectedDate == nil
    }

    /// The currently displayed date (resolves nil to today)
    private var currentDisplayDate: Date {
        selectedDate ?? calendar.startOfDay(for: Date())
    }

    /// Previous day (further into the past)
    private var previousDate: Date {
        calendar.date(byAdding: .day, value: -1, to: currentDisplayDate)!
    }

    /// Next day (toward today) - nil if already on today
    private var nextDate: Date? {
        guard !isViewingToday else { return nil }
        let next = calendar.date(byAdding: .day, value: 1, to: currentDisplayDate)!
        return next
    }

    /// Navigate to the previous day (further into the past)
    private func goToPreviousDay() {
        let newDate = calendar.date(byAdding: .day, value: -1, to: currentDisplayDate)!
        swipeFeedback.impactOccurred()
        selectedDate = newDate
        showingNewFastAfterSummary = false
    }

    /// Navigate to the next day (toward today)
    private func goToNextDay() {
        guard !isViewingToday else { return }
        let newDate = calendar.date(byAdding: .day, value: 1, to: currentDisplayDate)!
        swipeFeedback.impactOccurred()
        if calendar.isDateInToday(newDate) {
            selectedDate = nil
        } else {
            selectedDate = newDate
        }
        showingNewFastAfterSummary = false
    }

    /// Whether to show the summary view
    private var shouldShowSummary: Bool {
        // Allow viewing past date summaries even during active fast
        if selectedDate != nil && sessionForSelectedDate != nil { return true }
        // Never show today's summary if there's an active fast
        if activeSession != nil { return false }
        // Don't show if user just tapped "Start New Fast"
        if showingNewFastAfterSummary { return false }
        // Show if today has a completed session
        return todayCompletedSession != nil
    }

    /// The session to display in summary view
    private var summarySession: FastSession? {
        if let date = selectedDate {
            return sessionForSelectedDate
        }
        return todayCompletedSession
    }

    private var fastedDates: Set<DateComponents> {
        var dates = Set<DateComponents>()
        for session in completedSessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startAt)
            dates.insert(components)
        }
        return dates
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
            VStack(spacing: 0) {
                // Calendar section (compact by default, expandable)
                CalendarSection(
                    fastedDates: fastedDates,
                    selectedDate: $selectedDate,
                    onDateSelected: { date in
                        // Allow selecting any past date (including today)
                        if calendar.isDateInToday(date) {
                            selectedDate = nil
                        } else {
                            selectedDate = date
                        }
                        showingNewFastAfterSummary = false
                    }
                )
                .padding(.top, 12)

                // Main content area - paging day navigation
                GeometryReader { contentGeometry in
                    let pageWidth = contentGeometry.size.width

                    HStack(spacing: 0) {
                        // Previous day (to the left)
                        dayContent(for: previousDate, isToday: false)
                            .frame(width: pageWidth)

                        // Current day (center)
                        dayContent(for: currentDisplayDate, isToday: isViewingToday)
                            .frame(width: pageWidth)

                        // Next day (to the right) - or empty if on today
                        if let next = nextDate {
                            dayContent(for: next, isToday: calendar.isDateInToday(next))
                                .frame(width: pageWidth)
                        } else {
                            // Placeholder for today - nothing to the right
                            Color.clear
                                .frame(width: pageWidth)
                        }
                    }
                    .offset(x: -pageWidth + swipeOffset)  // Start showing current (middle) page
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                let horizontal = abs(value.translation.width)
                                let vertical = abs(value.translation.height)
                                guard horizontal > vertical * 1.2 else { return }

                                // Prevent swiping right (to future) when on today
                                if isViewingToday && value.translation.width > 0 {
                                    swipeOffset = value.translation.width * 0.3  // Rubber band effect
                                } else {
                                    swipeOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                let horizontal = abs(value.translation.width)
                                let vertical = abs(value.translation.height)
                                let velocityThreshold: CGFloat = 500

                                // Check if swipe should trigger page change
                                let shouldChangePage = horizontal > pageWidth * 0.3 ||
                                    abs(value.predictedEndTranslation.width) > velocityThreshold

                                if shouldChangePage && horizontal > vertical {
                                    if value.translation.width > 0 && !isViewingToday {
                                        // Swiped right - go to next day (toward today)
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            swipeOffset = pageWidth
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            swipeOffset = 0
                                            goToNextDay()
                                        }
                                    } else if value.translation.width < 0 {
                                        // Swiped left - go to previous day (into past)
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            swipeOffset = -pageWidth
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            swipeOffset = 0
                                            goToPreviousDay()
                                        }
                                    } else {
                                        // Rubber band back
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            swipeOffset = 0
                                        }
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        swipeOffset = 0
                                    }
                                }
                            }
                    )
                }
                .clipped()
            }
        }
        .onAppear {
            restoreSession()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                timerEngine.refresh()
            }
        }
        .onChange(of: timerEngine.remainingSeconds) { _, newValue in
            if newValue == 0, let session = activeSession {
                session.endAt = session.startAt.addingTimeInterval(session.targetDuration)
                try? modelContext.save()
                timerEngine.stop()
                selectedSeconds = 0
                selectedPreset = nil
                // Reset so summary view appears for the newly completed fast
                showingNewFastAfterSummary = false
                selectedDate = nil  // Return to today to show completion summary
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Fast")
                    .font(.largeTitle.bold())
                    #if DEBUG
                    .onTapGesture {
                        titleTapCount += 1
                        if titleTapCount >= 5 {
                            titleTapCount = 0
                            debugModeEnabled.toggle()
                            if debugModeEnabled {
                                FastApp.insertMockData(context: modelContext)
                            } else {
                                FastApp.clearMockData(context: modelContext)
                            }
                        }
                    }
                    #endif
            }
            ToolbarItem(placement: .topBarTrailing) {
                StatsView(completedSessions: completedSessions)
            }
        }
        }
    }

    private var progress: CGFloat {
        if let session = activeSession {
            let total = session.targetDuration
            let remaining = timerEngine.remainingSeconds
            return total > 0 ? CGFloat(remaining / total) : 1.0
        }
        // When selecting, show fill based on selection
        return CGFloat(selectedSeconds) / CGFloat(maxDuration)
    }

    private var handleAngle: Double {
        // Angle in degrees, 0 = top, clockwise
        360 * Double(selectedSeconds) / maxDuration
    }

    private var formattedTime: String {
        let totalSeconds: Int
        if activeSession != nil {
            totalSeconds = Int(timerEngine.remainingSeconds)
        } else {
            totalSeconds = selectedSeconds
        }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let session = activeSession {
            return formatter.string(from: session.startAt)
        }
        // Preview mode: show current time
        return formatter.string(from: Date())
    }

    private var endTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let session = activeSession {
            let endTime = session.startAt.addingTimeInterval(session.targetDuration)
            return formatter.string(from: endTime)
        }
        // Preview mode: show current time + selected duration
        let endTime = Date().addingTimeInterval(TimeInterval(selectedSeconds))
        return formatter.string(from: endTime)
    }

    @ViewBuilder
    private var timerView: some View {
        VStack(spacing: 0) {
            // Ring container - centers the ring in available space
            TimerRing(progress: progress) {
                // Draggable handle (only when not active)
                if activeSession == nil {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(y: -130)
                        .rotationEffect(.degrees(handleAngle))
                }

                // Timer text - always centered
                Text(formattedTime)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()

                // Start and end times - positioned below timer
                if activeSession != nil || selectedSeconds > 0 {
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text(activeSession != nil ? "Started" : "Starts")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(startTimeFormatted)
                                .font(.caption.weight(.medium))
                        }

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        VStack(spacing: 2) {
                            Text("Ends")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(endTimeFormatted)
                                .font(.caption.weight(.medium))
                        }
                    }
                    .offset(y: 40)
                }
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        guard activeSession == nil else { return }
                        let center = CGPoint(x: 130, y: 130)
                        let location = value.location
                        let dx = location.x - center.x
                        let dy = center.y - location.y
                        var angle = atan2(dx, dy) * 180 / .pi
                        if angle < 0 { angle += 360 }
                        let hours = Int(round(angle / 360 * 24)) % 24
                        if hours != lastDialHour {
                            dialFeedback.impactOccurred()
                            lastDialHour = hours
                        }
                        selectedSeconds = hours * 3600
                        selectedPreset = nil
                    }
            )
            .frame(maxHeight: .infinity)

            // Bottom content - fixed height for consistent layout
            VStack(spacing: 24) {
                // Preset pills (hidden when active session)
                HStack(spacing: 12) {
                    ForEach(fastingPresets, id: \.seconds) { preset in
                        Button {
                            if selectedPreset == preset.seconds {
                                selectedPreset = nil
                                selectedSeconds = 0
                            } else {
                                selectedSeconds = preset.seconds
                                selectedPreset = preset.seconds
                            }
                        } label: {
                            Text(preset.label)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedPreset == preset.seconds ? Color.primary : Color(.systemGray5))
                                )
                                .foregroundColor(selectedPreset == preset.seconds ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(activeSession == nil ? 1 : 0)

                Button {
                    if activeSession != nil {
                        stopFast()
                    } else {
                        startFast()
                    }
                } label: {
                    Label(
                        activeSession != nil ? "Stop" : "Start",
                        systemImage: activeSession != nil ? "stop.fill" : "play.fill"
                    )
                    .font(.headline)
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(activeSession == nil && selectedSeconds == 0)
            }
            .frame(height: 120)
        }
        .padding(.bottom, 20)
        .animation(nil, value: activeSession?.id)
    }

    /// Renders content for a specific date (used for paging)
    @ViewBuilder
    private func dayContent(for date: Date, isToday: Bool) -> some View {
        let session = sessionFor(date: date)
        let todaySession = isToday ? todayCompletedSession : nil

        // Determine what to show for this date
        if isToday {
            // Today's logic
            if activeSession != nil {
                // Active fast running - show timer
                timerView
            } else if !showingNewFastAfterSummary, let completed = todaySession {
                // Show today's completed fast summary
                FastSummaryView(session: completed, isToday: true) {
                    withAnimation {
                        showingNewFastAfterSummary = true
                    }
                }
            } else {
                // Show timer/dial for starting new fast
                timerView
            }
        } else {
            // Past date logic
            if let session = session {
                FastSummaryView(session: session, isToday: false) {
                    // No "Start New Fast" for past dates
                }
            } else {
                emptyStateView
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            TimerRing(progress: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No fast")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxHeight: .infinity)

            // Bottom content - fixed height for consistent layout
            VStack {
                Text("No fasting activity on this day")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(height: 120)
        }
        .padding(.bottom, 20)
    }

    private func startFast() {
        let targetDuration = TimeInterval(selectedSeconds)
        let session = FastSession(targetDuration: targetDuration)
        modelContext.insert(session)
        timerEngine.start(from: session.startAt, target: targetDuration)

        let endDate = session.startAt.addingTimeInterval(targetDuration)
        NotificationManager.shared.scheduleFastComplete(at: endDate)
    }

    private func stopFast() {
        guard let session = activeSession else { return }
        let elapsed = Date().timeIntervalSince(session.startAt)

        // Don't count fasts less than 1 minute
        if elapsed < 60 {
            modelContext.delete(session)
        } else {
            session.endAt = Date()
            // Reset so summary view appears for the completed fast
            showingNewFastAfterSummary = false
        }

        timerEngine.stop()
        NotificationManager.shared.cancelFastComplete()
        selectedSeconds = 0
        selectedPreset = nil
    }

    private func restoreSession() {
        if let session = activeSession {
            timerEngine.start(from: session.startAt, target: session.targetDuration)

            let endDate = session.startAt.addingTimeInterval(session.targetDuration)
            if endDate > Date() {
                NotificationManager.shared.scheduleFastComplete(at: endDate)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FastSession.self, inMemory: true)
}
