import SwiftUI

struct TimerScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var engine: TimerEngine

    @State private var confetti = 0
    @State private var celebrate = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    CircularTimer(progress: engine.progress,
                                  timeString: engine.timeString,
                                  phaseTitle: engine.phase.title,
                                  tint: engine.phase == .focus ? Theme.heroGradient
                                        : LinearGradient(colors: [Theme.mint, Theme.primaryHi], startPoint: .top, endPoint: .bottom),
                                  running: engine.isRunning)
                        .padding(.top, 8)

                    controls
                    partnerView
                }
                .padding(32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            ConfettiView(burst: confetti)
        }
        .onAppear {
            engine.onFocusCompleted = { minutes in
                let unlocked = progress.recordCompletedFocus(minutes: minutes)
                confetti += 1
                withAnimation(.spring) { celebrate = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { celebrate = false }
                }
                // 時數門檻解鎖的限定角色,排隊揭曉。
                if let first = unlocked.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        progress.pendingReveal = first
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("專注一下,解鎖你的英雄")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                XPBar(level: progress.level, progress: progress.levelProgress,
                      xpInto: progress.xpIntoLevel, xpSpan: progress.xpForNextLevel)
                    .frame(maxWidth: 320)
            }
            Spacer()
            StreakFlame(days: progress.currentStreak)
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            PrimaryButton(title: engine.isRunning ? "暫停" : "開始",
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
                CharacterPortrait(character: partner)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.gold, lineWidth: 2))
                    .scaleEffect(celebrate ? 1.18 : 1)
                    .rotationEffect(.degrees(celebrate ? 6 : 0))
                VStack(alignment: .leading, spacing: 3) {
                    Text(partner.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(celebrate ? "太棒了!我們又更強了!" : partner.tagline)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(maxWidth: 420)
        }
    }
}
