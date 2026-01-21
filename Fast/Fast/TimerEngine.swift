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
    @Published var remainingSeconds: TimeInterval = 0

    private var timer: Timer?
    private var startAt: Date?
    private var targetDuration: TimeInterval = 0

    func start(from date: Date, target: TimeInterval) {
        startAt = date
        targetDuration = target
        updateRemainingTime()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        startAt = nil
        targetDuration = 0
        remainingSeconds = 0
    }

    func refresh() {
        updateRemainingTime()
    }

    private func updateRemainingTime() {
        guard let startAt else { return }
        let elapsed = Date().timeIntervalSince(startAt)
        remainingSeconds = max(0, targetDuration - elapsed)
    }
}
