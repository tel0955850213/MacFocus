import Foundation
import SwiftUI

enum TimerPhase: String {
    case focus, shortBreak, longBreak, idle

    /// Localization key for the phase label (resolved by the view).
    var titleKey: String {
        switch self {
        case .focus: return "phase.focus"
        case .shortBreak: return "phase.shortBreak"
        case .longBreak: return "phase.longBreak"
        case .idle: return "phase.idle"
        }
    }
}

/// Pomodoro state machine. Completing a focus session calls onFocusCompleted(minutes).
@MainActor
final class TimerEngine: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published private(set) var remaining: Int = 25 * 60   // seconds
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusCount = 0

    // Configurable durations (minutes)
    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var roundsBeforeLongBreak = 4

    /// Called when a focus segment completes, with that segment's minutes.
    var onFocusCompleted: ((Int) -> Void)?

    private var timer: Timer?

    var totalForPhase: Int {
        switch phase {
        case .focus, .idle: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    var progress: Double {
        let total = totalForPhase
        return total > 0 ? 1 - Double(remaining) / Double(total) : 0
    }

    var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    /// Apply user settings. If idle, reflect the new focus length immediately.
    func apply(focus: Int, short: Int, long: Int, rounds: Int) {
        focusMinutes = focus
        shortBreakMinutes = short
        longBreakMinutes = long
        roundsBeforeLongBreak = rounds
        if phase == .idle && !isRunning { remaining = focusMinutes * 60 }
    }

    // MARK: - Controls

    func start() {
        if phase == .idle { phase = .focus; remaining = focusMinutes * 60 }
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate(); timer = nil
    }

    func reset() {
        pause()
        phase = .idle
        remaining = focusMinutes * 60
    }

    /// Skip the current phase (end it immediately).
    func skip() { advancePhase() }

    private func tick() {
        guard remaining > 0 else { advancePhase(); return }
        remaining -= 1
        if remaining == 0 { advancePhase() }
    }

    private func advancePhase() {
        pause()
        switch phase {
        case .focus:
            completedFocusCount += 1
            onFocusCompleted?(focusMinutes)
            let isLong = completedFocusCount % roundsBeforeLongBreak == 0
            phase = isLong ? .longBreak : .shortBreak
            remaining = (isLong ? longBreakMinutes : shortBreakMinutes) * 60
        case .shortBreak, .longBreak, .idle:
            phase = .focus
            remaining = focusMinutes * 60
        }
    }
}
