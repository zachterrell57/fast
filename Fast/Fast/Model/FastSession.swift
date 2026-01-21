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
    var targetDuration: TimeInterval = 16 * 3600

    var elapsedDuration: TimeInterval {
        (endAt ?? Date()).timeIntervalSince(startAt)
    }

    var remainingDuration: TimeInterval {
        max(0, targetDuration - elapsedDuration)
    }

    var isActive: Bool {
        endAt == nil
    }

    var isComplete: Bool {
        remainingDuration == 0
    }

    init(startAt: Date = Date(), targetDuration: TimeInterval = 16 * 3600) {
        self.id = UUID()
        self.startAt = startAt
        self.endAt = nil
        self.targetDuration = targetDuration
    }
}
