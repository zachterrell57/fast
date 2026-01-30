//
//  TimerEngine.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import Foundation
import Combine

@MainActor
class TimerEngine: ObservableObject {
    @Published var elapsedSeconds: TimeInterval = 0

    private var timer: Timer?
    private var startAt: Date?

    func start(from date: Date) {
        startAt = date
        updateElapsedTime()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        startAt = nil
        elapsedSeconds = 0
    }

    func refresh() {
        updateElapsedTime()
    }

    private func updateElapsedTime() {
        guard let startAt else { return }
        elapsedSeconds = Date().timeIntervalSince(startAt)
    }
}
