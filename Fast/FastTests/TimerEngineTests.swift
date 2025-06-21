import Foundation
import Testing
@testable import Fast

struct TimerEngineTests {

    // MARK: - Tests
    @Test func start_setsInitialElapsedAccurately() async throws {
        // Arrange – start 10 s in the past
        let start = Date().addingTimeInterval(-10)
        let session = FastSession(startAt: start)
        let engine = await MainActor.run { TimerEngine() }

        // Act
        await MainActor.run { engine.start(with: session) }

        // Assert – immediate elapsed should be close to 10 s (±1)
        let elapsed = await engine.elapsed
        #expect(elapsed >= 9 && elapsed <= 11)
    }

    @Test func elapsed_incrementsEachSecond() async throws {
        // Arrange
        let session = FastSession(startAt: Date())
        let engine = await MainActor.run { TimerEngine() }
        await MainActor.run { engine.start(with: session) }

        // Capture baseline
        let baseline = await engine.elapsed

        // Sleep ~1.1 s to allow ticker to fire at least once
        try await Task.sleep(nanoseconds: 1_100_000_000)

        let updated = await engine.elapsed
        #expect(updated >= baseline + 1)
    }
} 