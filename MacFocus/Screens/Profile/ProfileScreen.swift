import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Avatar = current companion
                if let p = progress.partner {
                    CharacterPortrait(character: p)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.heroGradient, lineWidth: 3))
                }
                Text(loc("profile.name"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lv. \(progress.level) · \(String(format: "%.1f", progress.totalFocusHours)) \(loc("unit.hours"))")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                XPBar(level: progress.level, progress: progress.levelProgress,
                      xpInto: progress.xpIntoLevel, xpSpan: progress.xpForNextLevel)
                    .frame(maxWidth: 320)

                freeCard
                    .frame(maxWidth: 360)

                VStack(spacing: 12) {
                    Text(loc("profile.cloudSync"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(loc("profile.cloudSoonDesc"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Label(loc("profile.cloudComingSoon"), systemImage: "icloud.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceHi.opacity(0.65), in: Capsule())
                }
                .padding(18)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: 360)

                Text("v1.0 · Focus Arcana")
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary.opacity(0.6))
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
    }

    private var freeCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.mint)
            VStack(alignment: .leading, spacing: 2) {
                Text(loc("free.title"))
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(loc("free.body"))
                    .font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
