import Foundation
import SwiftData

/// Thread-safe façade handling CRUD operations for `FastSession` models.
/// Abstraction decouples app logic from the underlying persistence mechanism (SwiftData).
@MainActor
final class FastRepository: ObservableObject {

    // MARK: – Public API

    /// Shared instance backed by the on-disk store.
    static let shared = FastRepository()

    /// Throws if an active session already exists.
    @discardableResult
    func startFast(at start: Date = .init()) throws -> FastSession {
        if try activeFast() != nil {
            throw Error.activeFastExists
        }

        let session = FastSession(startAt: start)
        context.insert(session)
        try context.save()
        return session
    }

    /// Marks the given session as completed by setting `endAt`.
    /// - Important: If `endAt` is already non-nil the call is a no-op.
    func endFast(_ session: FastSession, at end: Date = .init()) throws {
        guard session.endAt == nil else { return }
        session.endAt = end
        try context.save()
    }

    /// Permanently removes a session.
    func delete(_ session: FastSession) throws {
        context.delete(session)
        try context.save()
    }

    /// Fetches all sessions regardless of status.
    func all() throws -> [FastSession] {
        try context.fetch(FetchDescriptor<FastSession>())
    }

    /// Returns the currently active fast if one exists (i.e., `endAt == nil`).
    func activeFast() throws -> FastSession? {
        let predicate = #Predicate<FastSession> { $0.endAt == nil }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: – Private

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// Designated initializer. When `inMemory == true` an ephemeral store is used for unit tests.
    init(inMemory: Bool = false) {
        do {
            if inMemory {
                var config = ModelConfiguration(isStoredInMemoryOnly: true)
                self.container = try ModelContainer(for: FastSession.self, configurations: config)
            } else {
                self.container = try ModelContainer(for: FastSession.self)
            }
        } catch {
            fatalError("failed to load SwiftData container: \(error)")
        }
    }

    // MARK: – Error

    enum Error: Swift.Error {
        case activeFastExists
    }
} 