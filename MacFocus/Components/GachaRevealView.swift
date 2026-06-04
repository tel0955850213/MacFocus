import SwiftUI

/// Full-screen gacha reveal: light burst → splash art enters → rarity badge.
struct GachaRevealView: View {
    @EnvironmentObject var loc: LocalizationManager
    let character: GameCharacter
    let onDismiss: () -> Void

    @State private var rays = false
    @State private var cardIn = false
    @State private var showInfo = false
    @State private var confetti = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { dismiss() }

            // 旋轉光芒
            RadialBurst(color: rarityColor)
                .scaleEffect(rays ? 1.6 : 0.2)
                .opacity(rays ? 0.55 : 0)
                .rotationEffect(.degrees(rays ? 25 : 0))
                .animation(.easeOut(duration: 1.0), value: rays)

            VStack(spacing: 18) {
                CharacterPortrait(character: character)
                    .frame(width: 260, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Theme.rarityGradient(character.rarity), lineWidth: 4))
                    .shadow(color: rarityColor.opacity(0.8), radius: 30)
                    .scaleEffect(cardIn ? 1 : 0.4)
                    .opacity(cardIn ? 1 : 0)
                    .rotation3DEffect(.degrees(cardIn ? 0 : 90), axis: (x: 0, y: 1, z: 0))

                if showInfo {
                    VStack(spacing: 6) {
                        RarityBadge(rarity: character.rarity).scaleEffect(1.3)
                        Text(character.name)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(loc(character.title))
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text(loc(character.tagline))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                    Button(loc("gacha.collect"), action: dismiss)
                        .buttonStyle(.plain)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40).padding(.vertical, 12)
                        .background(Theme.heroGradient, in: Capsule())
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: 360)

            ConfettiView(burst: confetti)
        }
        .onAppear {
            rays = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.35)) { cardIn = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) { showInfo = true }
            if character.rarity >= .superRare {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { confetti += 1 }
            }
        }
    }

    private var rarityColor: Color {
        switch character.rarity {
        case .normal: return Theme.textSecondary
        case .rare: return Color(hex: 0x4D9DFF)
        case .superRare: return Theme.primaryHi
        case .ssr: return Theme.gold
        }
    }

    private func dismiss() { onDismiss() }
}

private struct RadialBurst: View {
    let color: Color
    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.9), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 18, height: 320)
                    .offset(y: -160)
                    .rotationEffect(.degrees(Double(i) / 16 * 360))
            }
        }
    }
}
