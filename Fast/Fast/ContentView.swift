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
    private let maxDuration: TimeInterval = 24 * 3600 // 24 hours
    private let dialFeedback = UIImpactFeedbackGenerator(style: .light)

    private var activeSession: FastSession? {
        activeSessions.first
    }

    private var fastedDates: Set<DateComponents> {
        let calendar = Calendar.current
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
                CalendarSection(fastedDates: fastedDates)

                // Timer section (bottom half)
                VStack(spacing: 24) {
                    Spacer()

                    // Countdown display with circular progress
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)

                        // Progress circle
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        // Draggable handle (only when not active)
                        if activeSession == nil {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 24, height: 24)
                                .shadow(radius: 2)
                                .offset(y: -110)
                                .rotationEffect(.degrees(handleAngle))
                        }

                        // Timer text
                        Text(formattedTime)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .monospacedDigit()
                    }
                    .frame(width: 220, height: 220)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard activeSession == nil else { return }
                                let center = CGPoint(x: 110, y: 110)
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
                                            .fill(selectedPreset == preset.seconds ? Color.accentColor : Color(.systemGray5))
                                    )
                                    .foregroundColor(selectedPreset == preset.seconds ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .opacity(activeSession == nil ? 1 : 0)

                    Spacer()

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
                .padding(.bottom, 20)
                .animation(nil, value: activeSession?.id)
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
