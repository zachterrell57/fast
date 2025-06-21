import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// Observable timer engine publishing the elapsed seconds for the currently active fast.
/// The engine computes the value from the `FastSession`\'s `startAt` timestamp on every tick,
/// ensuring accuracy even when the application spends time in the background where scheduled
/// timers are paused by the system.
@MainActor
final class TimerEngine: ObservableObject {
    // MARK: - Published
    /// Elapsed time in seconds since `session.startAt`. Updates once per second.
    @Published private(set) var elapsed: TimeInterval = 0

    // MARK: - Private Properties
    private var session: FastSession?
    private var timerCancellable: AnyCancellable?
    private var foregroundCancellable: AnyCancellable?

    // MARK: - Public API
    /// Begins publishing elapsed time for the supplied active session.
    /// - Parameter session: An **active** `FastSession` (`endAt == nil`). If the session has
    ///   already ended the method logs a warning and becomes a no-op.
    func start(with session: FastSession) {
        guard session.endAt == nil else {
            // Stopwatch is only meaningful for active fasts; ignore ended sessions.
            return
        }
        self.session = session
        updateElapsed()

        // Configure 1 s ticker.
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: 1, tolerance: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsed()
            }

        // Refresh immediately when the application re-enters foreground.
        #if os(iOS)
        foregroundCancellable?.cancel()
        foregroundCancellable = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateElapsed()
            }
        #endif
    }

    /// Stops the engine and clears subscriptions.
    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
        foregroundCancellable?.cancel()
        foregroundCancellable = nil
        session = nil
    }

    // MARK: - Helpers
    private func updateElapsed() {
        guard let session else { return }
        // Rely on `FastSession.duration` which accounts for active vs completed state.
        elapsed = session.duration
    }
} 