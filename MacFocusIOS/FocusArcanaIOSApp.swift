import SwiftUI

@main
struct FocusArcanaIOSApp: App {
    @StateObject private var progress: ProgressStore
    @StateObject private var engine: TimerEngine
    @StateObject private var settings: SettingsStore
    @StateObject private var loc: LocalizationManager
    @StateObject private var ambient: AmbientSoundPlayer

    init() {
        let progress = ProgressStore()
        let engine = TimerEngine()
        let settings = SettingsStore()
        let loc = LocalizationManager()
        let ambient = AmbientSoundPlayer()

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--screenshot-mode") {
            progress._debugSeedShowcase()
        }
        #endif

        engine.onFocusCompleted = { minutes, tag in
            let unlocked = progress.recordCompletedFocus(minutes: minutes, tag: tag)
            Notifier.focusFinished(settings: settings, loc: loc, minutes: minutes)
            if let first = unlocked.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    progress.pendingReveal = first
                }
            }
        }

        _progress = StateObject(wrappedValue: progress)
        _engine = StateObject(wrappedValue: engine)
        _settings = StateObject(wrappedValue: settings)
        _loc = StateObject(wrappedValue: loc)
        _ambient = StateObject(wrappedValue: ambient)
    }

    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environmentObject(progress)
                .environmentObject(engine)
                .environmentObject(settings)
                .environmentObject(loc)
                .environmentObject(ambient)
                .preferredColorScheme(.dark)
                .onAppear {
                    applyTimerSettings()
                    ambient.attach(to: engine, settings: settings)
                }
                .onChange(of: settings.focusMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.shortBreakMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.longBreakMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.roundsBeforeLongBreak) { _, _ in applyTimerSettings() }
        }
    }

    private func applyTimerSettings() {
        engine.apply(focus: settings.focusMinutes,
                     short: settings.shortBreakMinutes,
                     long: settings.longBreakMinutes,
                     rounds: settings.roundsBeforeLongBreak)
    }
}
