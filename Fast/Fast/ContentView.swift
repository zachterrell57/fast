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

    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var showingSettings = false
    @State private var editingStartTime = false
    @State private var editingCustomStartTime = false
    @State private var editStartDate = Date()
    @State private var customStartDate: Date? = nil
    @State private var selectedSeconds: Int = 0
    @State private var selectedPreset: Int? = nil
    @State private var lastDialHour: Int = 0
    @State private var selectedDate: Date? = nil  // nil = today, set to view past dates
    @State private var showingNewFastAfterSummary: Bool = false  // Force show dial after "Start New Fast"
    @State private var currentPageIndex: Int = 0  // 0 = today, negative = past days
    private let maxDuration: TimeInterval = 24 * 3600 // 24 hours
    private let dialFeedback = UIImpactFeedbackGenerator(style: .light)
    private let swipeFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let calendar = Calendar.current
    private let maxPastDays: Int = 90  // Number of past days available for navigation

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

    /// Get session for any arbitrary date (matches by end date since fasts are marked on the day they end)
    private func sessionFor(date: Date) -> FastSession? {
        return completedSessions
            .filter { session in
                guard let endAt = session.endAt else { return false }
                return calendar.isDate(endAt, inSameDayAs: date)
            }
            .sorted { ($0.endAt ?? .distantPast) > ($1.endAt ?? .distantPast) }
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

    /// Convert page index to date (0 = today, -1 = yesterday, etc.)
    private func dateForPageIndex(_ index: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: index, to: today)!
    }

    /// Convert date to page index
    private func pageIndexForDate(_ date: Date?) -> Int {
        guard let date = date else { return 0 }  // nil = today = index 0
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: targetDay).day ?? 0
    }

    /// Sync selectedDate when page changes via swipe
    private func handlePageChange(newIndex: Int) {
        swipeFeedback.impactOccurred()
        if newIndex == 0 {
            selectedDate = nil
        } else {
            selectedDate = dateForPageIndex(newIndex)
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
        if selectedDate != nil {
            return sessionForSelectedDate
        }
        return todayCompletedSession
    }

    private var fastedDates: Set<DateComponents> {
        var dates = Set<DateComponents>()
        for session in completedSessions {
            // Use endAt to mark the day the fast ended (overnight fasts end the next morning)
            let components = calendar.dateComponents([.year, .month, .day], from: session.endAt!)
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
                        let newIndex: Int
                        if calendar.isDateInToday(date) {
                            selectedDate = nil
                            newIndex = 0
                        } else {
                            selectedDate = date
                            newIndex = pageIndexForDate(date)
                        }
                        // Sync TabView page with calendar selection
                        withAnimation {
                            currentPageIndex = newIndex
                        }
                        showingNewFastAfterSummary = false
                    }
                )
                .padding(.top, 16)

                // Main content area - native paging with TabView
                TabView(selection: $currentPageIndex) {
                    // Generate pages from oldest (left) to today (right)
                    // Index -maxPastDays is furthest in the past, 0 is today
                    ForEach(-maxPastDays...0, id: \.self) { pageIndex in
                        let date = dateForPageIndex(pageIndex)
                        let isToday = pageIndex == 0

                        dayContent(for: date, isToday: isToday)
                            .tag(pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPageIndex) { oldIndex, newIndex in
                    handlePageChange(newIndex: newIndex)
                }
            }
        }
        .onAppear {
            restoreSession()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                timerEngine.refresh()

                // Manage hourly reminders based on fasting state
                if activeSession != nil {
                    NotificationManager.shared.cancelHourlyReminders()
                } else if reminderEnabled {
                    NotificationManager.shared.scheduleHourlyReminders(
                        fromHour: reminderHour, minute: reminderMinute
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Fast")
                    .font(.largeTitle.bold())
                    .padding(.top, 8)
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
                    .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        }
    }

    private var progress: CGFloat {
        if let session = activeSession {
            guard let total = session.targetDuration, total > 0 else {
                // No goal set - return nil-like value, handled by pulsing animation
                return 0
            }
            let elapsed = timerEngine.elapsedSeconds
            // Cap at 1.0 for ring display (elapsed / goal, grows from 0 to 1)
            return min(1.0, CGFloat(elapsed / total))
        }
        // When selecting, show fill based on selection
        return CGFloat(selectedSeconds) / CGFloat(maxDuration)
    }

    /// Whether the active session has no goal (for pulsing animation)
    private var isOpenEndedFast: Bool {
        guard let session = activeSession else { return false }
        return session.targetDuration == nil
    }

    private var handleAngle: Double {
        // Angle in degrees, 0 = top, clockwise
        360 * Double(selectedSeconds) / maxDuration
    }

    private var formattedTime: String {
        let totalSeconds: Int
        if activeSession != nil {
            totalSeconds = Int(timerEngine.elapsedSeconds)
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
        // Preview mode: show custom start time or current time
        return formatter.string(from: customStartDate ?? Date())
    }

    private var endTimeFormatted: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let session = activeSession {
            guard let targetDuration = session.targetDuration else { return nil }
            let endTime = session.startAt.addingTimeInterval(targetDuration)
            return formatter.string(from: endTime)
        }
        // Preview mode: show projected end based on start time + selected duration
        guard selectedSeconds > 0 else { return nil }
        let startTime = customStartDate ?? Date()
        let endTime = startTime.addingTimeInterval(TimeInterval(selectedSeconds))
        return formatter.string(from: endTime)
    }

    private var reminderTimeFormatted: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Reminder at \(formatter.string(from: date))"
    }

    /// Whether to show the end time (only when a goal is set)
    private var hasGoalToShow: Bool {
        if let session = activeSession {
            return session.targetDuration != nil
        }
        return selectedSeconds > 0
    }

    /// Dial rotation gesture for selecting fasting duration
    private var dialGesture: AnyGesture<DragGesture.Value> {
        AnyGesture(
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
    }

    @ViewBuilder
    private var timerView: some View {
        VStack(spacing: 0) {
            // Ring container - centers the ring in available space
            // Pass dial gesture only when no active session, so it's only captured on ring area
            TimerRing(progress: progress, isPulsing: isOpenEndedFast, dialGesture: activeSession == nil ? dialGesture : nil) {
                // Draggable handle (only when not active)
                if activeSession == nil {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(y: -130)
                        .rotationEffect(.degrees(handleAngle))
                }

                // Reminder indicator
                if activeSession == nil {
                    Button {
                        showingSettings = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: reminderEnabled ? "bell.fill" : "bell.slash")
                            Text(reminderEnabled ? reminderTimeFormatted : "Reminder off")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .offset(y: -40)
                }

                // Timer text - always centered
                Text(formattedTime)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()

                // Start and end times - positioned below timer
                // Show for active sessions (with or without goal) or when goal is selected before starting
                if activeSession != nil || selectedSeconds > 0 {
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text(activeSession != nil ? "Started" : "Starts")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(startTimeFormatted)
                                .font(.caption.weight(.medium))
                                .underline(color: .secondary.opacity(0.5))
                        }
                        .onTapGesture {
                            if let session = activeSession {
                                editStartDate = session.startAt
                                editingStartTime = true
                            } else if selectedSeconds > 0 {
                                editStartDate = customStartDate ?? Date()
                                editingCustomStartTime = true
                            }
                        }

                        // Only show end time section if a goal is set
                        if hasGoalToShow, let endTime = endTimeFormatted {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            VStack(spacing: 2) {
                                Text("Ends")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(endTime)
                                    .font(.caption.weight(.medium))
                            }
                        }
                    }
                    .offset(y: 40)
                }
            }
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
                                .foregroundColor(selectedPreset == preset.seconds ? Color(.systemBackground) : .primary)
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
            }
            .frame(height: 120)
        }
        .padding(.bottom, 20)
        .animation(nil, value: activeSession?.id)
        .sheet(isPresented: $editingStartTime) {
            TimeEditSheet(
                editType: .start,
                date: $editStartDate,
                maxDate: Date(),
                onSave: { newDate in
                    guard let session = activeSession else { return }
                    session.startAt = newDate
                    try? modelContext.save()
                    // Restart timer with updated start time
                    timerEngine.start(from: newDate)
                    // Reschedule notification if goal is set
                    if let targetDuration = session.targetDuration {
                        let endDate = newDate.addingTimeInterval(targetDuration)
                        if endDate > Date() {
                            NotificationManager.shared.scheduleFastComplete(at: endDate)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $editingCustomStartTime) {
            TimeEditSheet(
                editType: .start,
                date: $editStartDate,
                maxDate: Date(),
                onSave: { newDate in
                    customStartDate = newDate
                }
            )
        }
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
        let targetDuration: TimeInterval? = selectedSeconds > 0 ? TimeInterval(selectedSeconds) : nil
        let startDate = customStartDate ?? Date()
        let session = FastSession(startAt: startDate, targetDuration: targetDuration)
        modelContext.insert(session)
        timerEngine.start(from: session.startAt)

        // Only schedule notification if a goal is set
        if let duration = targetDuration {
            let endDate = session.startAt.addingTimeInterval(duration)
            if endDate > Date() {
                NotificationManager.shared.scheduleFastComplete(at: endDate)
            }
        }

        // Cancel hourly reminders since a fast has started
        NotificationManager.shared.cancelHourlyReminders()

        customStartDate = nil
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

        // Re-schedule hourly reminders since no fast is active
        if reminderEnabled {
            NotificationManager.shared.scheduleHourlyReminders(
                fromHour: reminderHour, minute: reminderMinute
            )
        }

        selectedSeconds = 0
        selectedPreset = nil
    }

    private func restoreSession() {
        if let session = activeSession {
            timerEngine.start(from: session.startAt)

            // Only schedule notification if a goal is set and not yet reached
            if let targetDuration = session.targetDuration {
                let endDate = session.startAt.addingTimeInterval(targetDuration)
                if endDate > Date() {
                    NotificationManager.shared.scheduleFastComplete(at: endDate)
                }
            }

            // Ensure hourly reminders are cancelled while fasting
            NotificationManager.shared.cancelHourlyReminders()
        } else if reminderEnabled {
            // No active fast — ensure hourly reminders are scheduled
            NotificationManager.shared.scheduleHourlyReminders(
                fromHour: reminderHour, minute: reminderMinute
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FastSession.self, inMemory: true)
}
