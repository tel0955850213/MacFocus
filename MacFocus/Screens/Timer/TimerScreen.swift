import SwiftUI

struct TimerScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var loc: LocalizationManager

    @State private var confetti = 0
    @State private var celebrate = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    CircularTimer(progress: engine.progress,
                                  timeString: engine.timeString,
                                  phaseTitle: loc(engine.phase.titleKey),
                                  tint: engine.phase == .focus ? Theme.heroGradient
                                        : LinearGradient(colors: [Theme.mint, Theme.primaryHi], startPoint: .top, endPoint: .bottom),
                                  running: engine.isRunning)
                        .padding(.top, 8)

                    if engine.phase == .idle {
                        TagPicker(selection: $engine.currentTag)
                            .frame(maxWidth: 360, alignment: .leading)
                    }

                    controls
                    partnerView
                }
                .padding(32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            ConfettiView(burst: confetti)
        }
        .onChange(of: progress.lastCompletion) { _, completion in
            // Rewards are recorded at the App level; this screen only celebrates.
            guard completion != nil else { return }
            confetti += 1
            withAnimation(.spring) { celebrate = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { celebrate = false }
            }
        }
        .onAppear {
            if engine.phase == .idle { engine.currentTag = settings.lastFocusTag }
        }
        .onChange(of: engine.currentTag) { _, tag in
            settings.lastFocusTag = tag
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(loc("timer.subtitle"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                XPBar(level: progress.level, progress: progress.levelProgress,
                      xpInto: progress.xpIntoLevel, xpSpan: progress.xpForNextLevel)
                    .frame(maxWidth: 320)
                DailyGoalRing(todayMinutes: progress.todayFocusMinutes,
                              goalMinutes: settings.dailyGoalMinutes)
            }
            Spacer()
            StreakFlame(days: progress.currentStreak)
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            PrimaryButton(title: engine.isRunning ? loc("timer.pause") : loc("timer.start"),
                          systemImage: engine.isRunning ? "pause.fill" : "play.fill") {
                engine.isRunning ? engine.pause() : engine.start()
            }
            Button { engine.skip() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.surfaceHi, in: Circle())
            }.buttonStyle(.plain)
            Button { engine.reset() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.surfaceHi, in: Circle())
            }.buttonStyle(.plain)
        }
        .frame(maxWidth: 360)
    }

    @ViewBuilder private var partnerView: some View {
        if let partner = progress.partner {
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    Button {
                        engine.isRunning ? engine.pause() : engine.start()
                    } label: {
                        ZStack {
                            CharacterPortrait(character: partner,
                                              assetNameOverride: progress.displayAssetName(for: partner))
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.gold, lineWidth: 2))
                                .scaleEffect(celebrate ? 1.18 : 1)
                                .rotationEffect(.degrees(celebrate ? 6 : 0))

                            // Small play/pause badge so it reads as tappable.
                            Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Theme.accent, in: Circle())
                                .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                                .offset(x: 26, y: 26)
                        }
                    }
                    .buttonStyle(PartnerButtonStyle())
                    .help(loc("timer.partnerHint"))

                    if engine.phase != .idle {
                        Button { engine.reset() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Theme.textSecondary, in: Circle())
                                .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: -6)
                        .help(loc("timer.cancelHint"))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(partner.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if celebrate {
                        Text(loc("timer.celebrate"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    } else if engine.phase != .idle {
                        Text("\(loc(engine.phase.titleKey)) · \(engine.timeString)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .monospacedDigit()
                    } else {
                        Text(loc(partner.tagline))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    BondMeter(character: partner, compact: true)
                        .frame(width: 150)
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(maxWidth: 420)
        }
    }
}

/// Subtle press-down scale for the tappable partner portrait.
private struct PartnerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
