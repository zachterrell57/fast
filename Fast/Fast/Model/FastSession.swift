import Foundation
import SwiftData

// A persistent model representing one fasting session.
// Stored locally via SwiftData; unique by `id`.
@Model
final class FastSession: Identifiable {
    // MARK: - Stored Properties
    @Attribute(.unique) var id: UUID
    var startAt: Date
    var endAt: Date?

    // MARK: - Computed
    /// Elapsed duration in seconds. Uses the current clock while the session is active.
    var duration: TimeInterval {
        if let endAt { // completed session
            return endAt.timeIntervalSince(startAt)
        }
        // active session – compute against now
        return Date().timeIntervalSince(startAt)
    }

    // MARK: - Initialization
    init(id: UUID = UUID(), startAt: Date = Date(), endAt: Date? = nil) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
    }
} 