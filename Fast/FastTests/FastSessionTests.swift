import Foundation
import Testing
@testable import Fast

struct FastSessionTests {

    // MARK: - Helpers
    private func makeDate(offset seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    // MARK: - Tests
    @Test func duration_returnsExpected_whenSessionEnded() async throws {        
        let start = makeDate(offset: 0)
        let end = makeDate(offset: 3_600) // +1h
        let session = FastSession(startAt: start, endAt: end)

        let duration = session.duration

        #expect(duration == 3_600)
    }

    @Test func duration_nonNegative_whileActive() async throws {
        let start = Date()
        let session = FastSession(startAt: start)

        let duration = session.duration

        #expect(duration >= 0)
    }
} 