import Foundation
import SwiftUI

enum TimerPhase: String {
    case focus, shortBreak, longBreak, idle

    var title: String {
        switch self {
        case .focus: return "專注中"
        case .shortBreak: return "短休息"
        case .longBreak: return "長休息"
        case .idle: return "準備開始"
        }
    }
}

/// 番茄鐘狀態機。完成一次 focus 會回呼 onFocusCompleted(minutes)。
@MainActor
final class TimerEngine: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published private(set) var remaining: Int = 25 * 60   // 秒
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusCount = 0

    // 可設定的時長(分鐘)
    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var roundsBeforeLongBreak = 4

    /// 完成一段專注時呼叫,傳入該段分鐘數。
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

    /// 略過目前階段(直接結束)。
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
