import SwiftUI

struct GachaScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var loc: LocalizationManager
    @State private var shake = false

    var canDraw: Bool { progress.coins >= progress.drawCost }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(loc("gacha.title"))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(loc("gacha.subtitle"))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                // Summoning crystal
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Theme.primaryHi.opacity(0.7), Theme.primary.opacity(0.1)],
                                             center: .center, startRadius: 10, endRadius: 130))
                        .frame(width: 240, height: 240)
                        .blur(radius: 8)
                    Image(systemName: "sparkles")
                        .font(.system(size: 90, weight: .light))
                        .foregroundStyle(Theme.goldGradient)
                        .rotationEffect(.degrees(shake ? 8 : -8))
                }
                .frame(height: 260)
                .animation(.easeInOut(duration: 0.12).repeatCount(6, autoreverses: true), value: shake)

                rarityOdds

                PrimaryButton(title: canDraw ? String(format: loc("gacha.draw"), progress.drawCost) : loc("gacha.notEnough"),
                              systemImage: "wand.and.stars",
                              gradient: Theme.goldGradient,
                              enabled: canDraw) {
                    shake.toggle()
                    Notifier.effect(settings: settings)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        _ = progress.drawGacha()
                    }
                }
                .frame(maxWidth: 320)

                Text(String(format: loc("gacha.coins"), progress.coins))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.gold)

#if DEBUG
                Button(loc("gacha.debugGrant")) { progress._debugGrant(coins: 500) }
                    .buttonStyle(.plain).foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .font(.system(size: 11))
#endif
            }
            .padding(32)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private var rarityOdds: some View {
        HStack(spacing: 10) {
            ForEach(Rarity.allCases.reversed(), id: \.self) { r in
                let total = CharacterCatalog.gachaPool.reduce(0.0) { $0 + $1.rarity.drawWeight }
                let w = CharacterCatalog.gachaPool.filter { $0.rarity == r }.reduce(0.0) { $0 + $1.rarity.drawWeight }
                VStack(spacing: 4) {
                    RarityBadge(rarity: r)
                    Text(total > 0 ? String(format: "%.0f%%", w / total * 100) : "—")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}
