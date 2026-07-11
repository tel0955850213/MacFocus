import SwiftUI

/// Content of the menu-bar popover: a compact timer + controls, so the user
/// never has to open the main window to run a focus session.
struct MenuBarPopoverView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var settings: SettingsStore
    var onOpenApp: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                if let partner = progress.partner {
                    CharacterPortrait(character: partner)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.gold, lineWidth: 1.5))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(loc(engine.phase.titleKey))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Text(engine.timeString)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                PrimaryButton(title: engine.isRunning ? loc("timer.pause") : loc("timer.start"),
                              systemImage: engine.isRunning ? "pause.fill" : "play.fill") {
                    engine.isRunning ? engine.pause() : engine.start()
                }
                Button { engine.skip() } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.surfaceHi, in: Circle())
                }.buttonStyle(.plain)
            }

            if engine.phase == .idle {
                TagPicker(selection: $engine.currentTag)
            }

            Divider().overlay(Theme.surfaceHi)

            Button {
                onOpenApp()
            } label: {
                Label(loc("menubar.openApp"), systemImage: "macwindow")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain)

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(loc("menubar.quit"), systemImage: "power")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 240)
        .background(Theme.bg)
    }
}
