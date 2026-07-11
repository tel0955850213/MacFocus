import SwiftUI

@main
struct MacFocusApp: App {
    @StateObject private var progress: ProgressStore
    @StateObject private var pet: PetController
    @StateObject private var engine: TimerEngine
    @StateObject private var settings: SettingsStore
    @StateObject private var loc: LocalizationManager
    @StateObject private var ambient: AmbientSoundPlayer
    @StateObject private var statusBar: StatusBarController

    init() {
        let progress = ProgressStore()
        let engine = TimerEngine()
        let settings = SettingsStore()
        let loc = LocalizationManager()
        let ambient = AmbientSoundPlayer()
        let statusBar = StatusBarController()

        // Rewards are recorded here, at the App level, so a session completed via
        // the menu bar or desktop pet still counts even if the main window was
        // never opened. TimerScreen only reacts (confetti) via lastCompletion.
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
        _statusBar = StateObject(wrappedValue: statusBar)
        _pet = StateObject(wrappedValue: PetController())
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(progress)
                .environmentObject(pet)
                .environmentObject(engine)
                .environmentObject(settings)
                .environmentObject(loc)
                .environmentObject(ambient)
                .frame(minWidth: 920, minHeight: 640)
                .preferredColorScheme(.dark)
                .onAppear { applyTimerSettings() }
                .onChange(of: settings.focusMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.shortBreakMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.longBreakMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.roundsBeforeLongBreak) { _, _ in applyTimerSettings() }
                .onChange(of: settings.hideDockIcon) { _, hidden in
                    AppLifecycle.setDockIconVisible(!hidden)
                }
                .onChange(of: settings.launchAtLogin) { _, enabled in
                    AppLifecycle.setLaunchAtLogin(enabled)
                }
                .onAppear {
                    AppLifecycle.setDockIconVisible(!settings.hideDockIcon)
                    AppLifecycle.setLaunchAtLogin(settings.launchAtLogin)
                    ambient.attach(to: engine, settings: settings)
                    statusBar.attach(engine: engine, progress: progress, loc: loc, settings: settings)
                    statusBar.setVisible(settings.showMenuBarTimer)
                }
                .onChange(of: settings.showMenuBarTimer) { _, visible in
                    statusBar.setVisible(visible)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)

    }

    private func applyTimerSettings() {
        engine.apply(focus: settings.focusMinutes,
                     short: settings.shortBreakMinutes,
                     long: settings.longBreakMinutes,
                     rounds: settings.roundsBeforeLongBreak)
    }
}
