import SwiftUI

@main
struct MacFocusApp: App {
    @StateObject private var progress = ProgressStore()
    @StateObject private var pet = PetController()
    @StateObject private var engine = TimerEngine()
    @StateObject private var settings = SettingsStore()
    @StateObject private var loc = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progress)
                .environmentObject(pet)
                .environmentObject(engine)
                .environmentObject(settings)
                .environmentObject(loc)
                .frame(minWidth: 920, minHeight: 640)
                .preferredColorScheme(.dark)
                .onAppear { applyTimerSettings() }
                .onChange(of: settings.focusMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.shortBreakMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.longBreakMinutes) { _, _ in applyTimerSettings() }
                .onChange(of: settings.roundsBeforeLongBreak) { _, _ in applyTimerSettings() }
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
