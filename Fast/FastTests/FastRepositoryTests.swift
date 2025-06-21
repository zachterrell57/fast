import Foundation
import Testing
@testable import Fast

@MainActor
struct FastRepositoryTests {

    // MARK: - Helpers
    private func makeRepo() -> FastRepository {
        FastRepository(inMemory: true)
    }

    // MARK: - Tests
    @Test func startFast_createsActiveSession() async throws {
        let repo = makeRepo()

        let session = try repo.startFast()

        // active fast exists
        let active = try repo.activeFast()
        #expect(active?.id == session.id)
    }

    @Test func startFast_fails_whenActiveExists() async throws {
        let repo = makeRepo()
        _ = try repo.startFast()

        var didThrow = false
        do {
            _ = try repo.startFast()
        } catch FastRepository.Error.activeFastExists {
            didThrow = true
        }
        #expect(didThrow)
    }

    @Test func endFast_completesActiveSession() async throws {
        let repo = makeRepo()
        let session = try repo.startFast()

        try repo.endFast(session)
        #expect(session.endAt != nil)

        let active = try repo.activeFast()
        #expect(active == nil)
    }

    @Test func delete_removesSession() async throws {
        let repo = makeRepo()
        let session = try repo.startFast()
        try repo.endFast(session)

        try repo.delete(session)

        let all = try repo.all()
        #expect(all.isEmpty)
    }
} 
