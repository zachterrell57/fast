import SwiftUI
import Combine

/// Primary UI showing a large count-up timer for the user's current fast.
/// Provides a single CTA that toggles between **Start** and **End** based on
/// whether an active fast exists.
@MainActor
struct TimerView: View {
    // MARK: – State
    @StateObject private var viewModel = TimerViewModel()

    // MARK: – View
    var body: some View {
        VStack(spacing: 32) {
            // Large monospaced timer string
            Text(viewModel.formatted)
                .font(.system(size: 64, weight: .medium, design: .monospaced))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .padding(.horizontal)

            // Start / End button
            Button(action: { viewModel.toggle() }) {
                Text(viewModel.isActive ? "End" : "Start")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 64)
        .animation(.default, value: viewModel.isActive)
    }
}

// MARK: – Preview
#Preview {
    TimerView()
}

// MARK: – ViewModel
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: – Published
    @Published var formatted: String
    @Published var isActive = false

    // MARK: – Private
    private let repository: FastRepository
    private let engine: TimerEngine
    private var cancellables = Set<AnyCancellable>()

    // MARK: – Init
    init(repository: FastRepository? = nil, engine: TimerEngine? = nil) {
        let repo = repository ?? FastRepository.shared
        let eng = engine ?? TimerEngine()
        self.repository = repo
        self.engine = eng
        self.formatted = Self.format(0)
        bind()
        restoreActiveFast()
    }

    // MARK: – Public
    /// Called by the button to toggle between starting and ending a fast.
    func toggle() {
        if isActive {
            endFast()
        } else {
            startFast()
        }
    }

    // MARK: – Private Helpers
    private func bind() {
        engine.$elapsed
            .map(Self.format)
            .sink { [weak self] in self?.formatted = $0 }
            .store(in: &cancellables)
    }

    private func restoreActiveFast() {
        guard let session = try? repository.activeFast() else { return }
        engine.start(with: session)
        isActive = true
    }

    private func startFast() {
        do {
            let session = try repository.startFast()
            engine.start(with: session)
            isActive = true
        } catch {
            // Edge case: Another active fast already exists.
            restoreActiveFast()
        }
    }

    private func endFast() {
        guard let session = try? repository.activeFast() else { return }
        do {
            try repository.endFast(session)
            engine.stop()
            // Retain the final duration after stopping.
            formatted = Self.format(session.duration)
            isActive = false
        } catch {
            // Fall back to stopping engine to avoid stuck state.
            engine.stop()
            isActive = false
        }
    }

    /// Formats a `TimeInterval` into `HH:MM:SS`.
    private static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let hours = total / 3600
        let minutes = (total / 60) % 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
} 