//
//  FastSession.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import Foundation
import SwiftData

@Model
class FastSession {
    var id: UUID
    var startAt: Date
    var endAt: Date?
    var targetDuration: TimeInterval?
    var deletedAt: Date?

    var elapsedDuration: TimeInterval {
        (endAt ?? Date()).timeIntervalSince(startAt)
    }

    var hasGoal: Bool {
        targetDuration != nil
    }

    var remainingDuration: TimeInterval? {
        guard let target = targetDuration else { return nil }
        return max(0, target - elapsedDuration)
    }

    var isActive: Bool {
        endAt == nil
    }

    var goalReached: Bool {
        guard let target = targetDuration else { return false }
        return elapsedDuration >= target
    }

    init(startAt: Date = Date(), targetDuration: TimeInterval? = nil) {
        self.id = UUID()
        self.startAt = startAt
        self.endAt = nil
        self.targetDuration = targetDuration
    }
}
