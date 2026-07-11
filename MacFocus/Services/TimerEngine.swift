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

    /// Called when a focus segment completes, with that segment's minutes and tag.
    var onFocusCompleted: ((Int, String?) -> Void)?

    /// Optional session label (Work/Study/…), captured when focus starts.
    var currentTag: String? = nil
    private var activeTag: String? = nil

    private var timer: Timer?
    /// Wall-clock end of the running phase. Ticking derives `remaining` from this
    /// instead of decrementing a counter, so App Nap throttling (menu-bar-only
    /// mode, all windows closed) can't stall the countdown.
    private var endDate: Date?
    private var activity: NSObjectProtocol?

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
        let startsNewFocus = phase == .idle || (phase == .focus && remaining == focusMinutes * 60)
        if phase == .idle { phase = .focus; remaining = focusMinutes * 60 }
        guard !isRunning else { return }
        if startsNewFocus { activeTag = currentTag }
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        beginActivity()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer?.tolerance = 0.1
    }

    func pause() {
        if let endDate { remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded())) }
        endDate = nil
        isRunning = false
        timer?.invalidate(); timer = nil
        endActivity()
    }

    func reset() {
        pause()
        phase = .idle
        remaining = focusMinutes * 60
    }

    /// Skip the current phase (end it immediately).
    func skip() { advancePhase() }

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
        if remaining == 0 { advancePhase() }
    }

    /// Keep the process out of App Nap while a phase is counting down; without
    /// this the timer stalls once the dock icon is hidden and no window is open.
    private func beginActivity() {
        guard activity == nil else { return }
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Focus timer running")
    }

    private func endActivity() {
        if let activity { ProcessInfo.processInfo.endActivity(activity) }
        activity = nil
    }

    private func advancePhase() {
        pause()
        switch phase {
        case .focus:
            completedFocusCount += 1
            onFocusCompleted?(focusMinutes, activeTag)
            activeTag = nil
            let isLong = completedFocusCount % roundsBeforeLongBreak == 0
            phase = isLong ? .longBreak : .shortBreak
            remaining = (isLong ? longBreakMinutes : shortBreakMinutes) * 60
        case .shortBreak, .longBreak, .idle:
            phase = .focus
            remaining = focusMinutes * 60
        }
    }
}
