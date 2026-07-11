import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var ambient: AmbientSoundPlayer
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(loc("settings.title"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                languageSection
                timerSection
                notifSection
                ambientSection
                appPresenceSection
                dataSection
            }
            .padding(32)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        SettingsCard(title: loc("settings.language")) {
            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        loc.language = lang
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: loc.language == lang
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(loc.language == lang
                                                 ? Theme.primaryHi
                                                 : Theme.textSecondary)
                            Text(loc(lang.displayKey))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)

                    if lang != AppLanguage.allCases.last {
                        Divider().overlay(Theme.surfaceHi)
                    }
                }
            }
        }
    }

    // MARK: - Timer

    private var timerSection: some View {
        SettingsCard(title: loc("settings.timer")) {
            stepperRow(loc("settings.focusLen"), value: $settings.focusMinutes,
                       range: 5...90, step: 5, unit: loc("unit.min"))
            Divider().overlay(Theme.surfaceHi)
            stepperRow(loc("settings.shortBreak"), value: $settings.shortBreakMinutes,
                       range: 1...30, step: 1, unit: loc("unit.min"))
            Divider().overlay(Theme.surfaceHi)
            stepperRow(loc("settings.longBreak"), value: $settings.longBreakMinutes,
                       range: 5...45, step: 5, unit: loc("unit.min"))
            Divider().overlay(Theme.surfaceHi)
            stepperRow(loc("settings.rounds"), value: $settings.roundsBeforeLongBreak,
                       range: 2...8, step: 1, unit: loc("unit.rounds"))
            Divider().overlay(Theme.surfaceHi)
            stepperRow(loc("settings.dailyGoal"), value: $settings.dailyGoalMinutes,
                       range: 30...480, step: 30, unit: loc("unit.min"))
        }
    }

    // MARK: - Notifications & sound

    private var notifSection: some View {
        SettingsCard(title: loc("settings.notifSound")) {
            toggleRow(loc("settings.completeSound"), isOn: $settings.completionSound)
            Divider().overlay(Theme.surfaceHi)
            toggleRow(loc("settings.systemNotif"), isOn: $settings.systemNotifications)
                .onChange(of: settings.systemNotifications) { _, enabled in
                    if enabled { Notifier.requestNotificationPermission() }
                }
            Divider().overlay(Theme.surfaceHi)
            toggleRow(loc("settings.sfx"), isOn: $settings.soundEffects)
        }
    }

    // MARK: - Data & about

    private var appPresenceSection: some View {
        SettingsCard(title: loc("settings.appPresence")) {
            toggleRow(loc("settings.menuBarTimer"), isOn: $settings.showMenuBarTimer)
            Divider().overlay(Theme.surfaceHi)
            toggleRow(loc("settings.hideDock"), isOn: $settings.hideDockIcon)
            Divider().overlay(Theme.surfaceHi)
            toggleRow(loc("settings.launchAtLogin"), isOn: $settings.launchAtLogin)
            if settings.launchAtLogin && AppLifecycle.launchAtLoginNeedsApproval {
                Text(loc("settings.launchApproval"))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.gold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var ambientSection: some View {
        SettingsCard(title: loc("settings.ambient")) {
            ForEach(AmbientSound.allCases) { sound in
                Button {
                    select(sound)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon(for: sound))
                            .frame(width: 18)
                            .foregroundStyle(selectedSound == sound ? Theme.primaryHi : Theme.textSecondary)
                        Text(loc(sound.labelKey))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        if selectedSound == sound {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.primaryHi)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
                if sound != AmbientSound.allCases.last {
                    Divider().overlay(Theme.surfaceHi)
                }
            }

            Divider().overlay(Theme.surfaceHi)
            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(Theme.textSecondary)
                Slider(value: $settings.ambientVolume, in: 0...1)
                    .tint(Theme.primaryHi)
                    .disabled(selectedSound == .none)
                Text("\(Int(settings.ambientVolume * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 34, alignment: .trailing)
            }
        }
    }

    // MARK: - Data & about

    private var dataSection: some View {
        SettingsCard(title: loc("settings.data")) {
            HStack {
                Text(loc("settings.resetProgress"))
                    .font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Button(loc("settings.reset")) { showResetConfirm = true }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Theme.accent, in: Capsule())
            }
            .confirmationDialog(loc("settings.resetConfirm"), isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button(loc("settings.reset"), role: .destructive) { progress.resetAll() }
                Button(loc("common.cancel"), role: .cancel) {}
            }
            Divider().overlay(Theme.surfaceHi)
            infoRow(loc("settings.version"), trailing: "1.0 (3)")
            Divider().overlay(Theme.surfaceHi)
            HStack {
                Text(loc("settings.github")).font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Link("github.com/tel0955850213/MacFocus",
                     destination: URL(string: "https://github.com/tel0955850213/MacFocus")!)
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.primaryHi)
            }
            Divider().overlay(Theme.surfaceHi)
            HStack {
                Text(loc("settings.feedback")).font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Link("880319dai@gmail.com",
                     destination: URL(string: "mailto:880319dai@gmail.com?subject=MacFocus%20Feedback")!)
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.primaryHi)
            }
        }
    }

    // MARK: - Reusable rows

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>,
                            step: Int, unit: String) -> some View {
        HStack {
            Text(title).font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
            Spacer()
            Text("\(value.wrappedValue) \(unit)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .frame(minWidth: 64, alignment: .trailing)
            Stepper("", value: value, in: range, step: step).labelsHidden()
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Theme.primaryHi)
        }
    }

    private func infoRow(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title).font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
            Spacer()
            Text(trailing).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.textSecondary)
        }
    }

    private var selectedSound: AmbientSound {
        AmbientSound(rawValue: settings.ambientSound) ?? .none
    }

    private func select(_ sound: AmbientSound) {
        settings.ambientSound = sound.rawValue
        ambient.preview(sound)
    }

    private func icon(for sound: AmbientSound) -> String {
        switch sound {
        case .none: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .whitenoise: return "waveform"
        case .cafe: return "cup.and.saucer.fill"
        case .lofiPad: return "music.note"
        }
    }
}

/// A titled rounded card that lays its rows out vertically.
private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
            VStack(spacing: 12) { content }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
