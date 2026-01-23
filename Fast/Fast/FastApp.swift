//
//  FastApp.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import SwiftUI
import SwiftData

@main
struct FastApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: FastSession.self)
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "debugModeEnabled") {
                insertMockDataIfNeeded(context: container.mainContext)
            }
            #endif
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(container)
    }

    #if DEBUG
    private func insertMockDataIfNeeded(context: ModelContext) {
        let hasInsertedMockData = UserDefaults.standard.bool(forKey: "hasInsertedMockData")
        guard !hasInsertedMockData else { return }

        FastApp.insertMockData(context: context)
        UserDefaults.standard.set(true, forKey: "hasInsertedMockData")
    }

    static func insertMockData(context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // Create mock fasting sessions for various days in the past
        let daysAgo = [2, 4, 5, 7, 9, 12, 14, 16, 18, 21, 25, 28]

        for days in daysAgo {
            guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else { continue }

            // Vary start time between 6 PM and 10 PM with random minutes
            var startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
            startComponents.hour = Int.random(in: 18...22)
            startComponents.minute = [0, 15, 30, 45].randomElement()!
            guard let startAt = calendar.date(from: startComponents) else { continue }

            // Target duration from common fasting goals
            let targetHours = [12, 14, 16, 18].randomElement()!
            let targetDuration = TimeInterval(targetHours * 3600)

            // Actual fast duration (sometimes slightly over/under target, with minute variation)
            let actualMinutes = (targetHours * 60) + Int.random(in: -45...90)
            guard let endAt = calendar.date(byAdding: .minute, value: actualMinutes, to: startAt) else { continue }

            let session = FastSession(startAt: startAt, targetDuration: targetDuration)
            session.endAt = endAt
            context.insert(session)
        }

        try? context.save()
    }

    static func clearMockData(context: ModelContext) {
        do {
            try context.delete(model: FastSession.self)
            try context.save()
            UserDefaults.standard.set(false, forKey: "hasInsertedMockData")
        } catch {
            print("Failed to clear mock data: \(error)")
        }
    }
    #endif
}
