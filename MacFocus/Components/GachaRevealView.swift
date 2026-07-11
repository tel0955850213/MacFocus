import SwiftUI

/// Full-screen summon reveal with a staged portal, card lift, and rarity burst.
/// The background is intentionally not dismissible so a click cannot erase the
/// reveal before the player has seen the result.
struct GachaRevealView: View {
    @EnvironmentObject var loc: LocalizationManager
    let character: GameCharacter
    let onDismiss: () -> Void

    @State private var portalOpen = false
    @State private var beamActive = false
    @State private var cardIn = false
    @State private var showInfo = false
    @State private var confetti = 0
    @State private var didStart = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            PortalBackdrop(
                color: rarityColor,
                intensity: portalOpen ? 1 : 0,
                beamActive: beamActive)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(showInfo ? character.rarity.label : loc("gacha.opening"))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(rarityColor)
                    .tracking(3)
                    .opacity(showInfo ? 1 : 0.8)

                ZStack {
                    CardBack(color: rarityColor)
                        .frame(width: 270, height: 350)
                        .scaleEffect(cardIn ? 0.86 : 1)
                        .opacity(cardIn ? 0 : 1)

                    ZStack {
                        CharacterPortrait(character: character)
                            .frame(width: 270, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        ClassicCardFrame(character: character, accent: rarityColor)
                    }
                    .frame(width: 270, height: 350)
                    .shadow(color: rarityColor.opacity(0.95), radius: 34)
                    .scaleEffect(cardIn ? 1 : 0.58)
                    .opacity(cardIn ? 1 : 0)
                    .rotation3DEffect(.degrees(cardIn ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .rotationEffect(.degrees(cardIn ? 0 : -8))
                    .onTapGesture {
                        if !showInfo { revealNow() }
                    }
                }
                .frame(width: 290, height: 360)

                if showInfo {
                    VStack(spacing: 6) {
                        RarityBadge(rarity: character.rarity)
                            .scaleEffect(1.35)
                        Text(character.name)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(loc(character.title))
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text(loc(character.tagline))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.top, 3)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                    Button(loc("gacha.collect"), action: onDismiss)
                        .buttonStyle(.plain)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 46)
                        .padding(.vertical, 13)
                        .background(Theme.heroGradient, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.24), lineWidth: 1))
                        .shadow(color: Theme.primary.opacity(0.55), radius: 18, y: 8)
                        .padding(.top, 4)
                } else {
                    Text(loc("gacha.revealHint"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: 380)

            if !showInfo {
                Button(loc("gacha.skip"), action: revealNow)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.surface.opacity(0.8), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(24)
                    .transition(.opacity)
            }

            ConfettiView(burst: confetti)
        }
        .onAppear { startReveal() }
    }

    private var rarityColor: Color {
        switch character.rarity {
        case .normal: return Theme.textSecondary
        case .rare: return Color(hex: 0x4D9DFF)
        case .superRare: return Color(hex: 0xB94DFF)
        case .ssr: return Theme.gold
        }
    }

    private func startReveal() {
        guard !didStart else { return }
        didStart = true
        withAnimation(.easeOut(duration: 0.42)) { portalOpen = true }
        withAnimation(.easeInOut(duration: 0.8).delay(0.25)) { beamActive = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.68)) { cardIn = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.46) {
            withAnimation(.easeOut(duration: 0.38)) { showInfo = true }
            if character.rarity >= .superRare { confetti += 1 }
        }
    }

    private func revealNow() {
        withAnimation(.spring(response: 0.46, dampingFraction: 0.78)) {
            portalOpen = true
            beamActive = true
            cardIn = true
            showInfo = true
        }
        if character.rarity >= .superRare { confetti += 1 }
    }
}

private struct CardBack: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [Theme.surfaceHi, Theme.surface, Color(hex: 0x0A101B)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(color.opacity(0.85), lineWidth: 4)
                }
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [5, 8]))
                .padding(14)
            Image(systemName: "bolt.fill")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.8), radius: 20)
        }
    }
}

private struct ClassicCardFrame: View {
    @EnvironmentObject var loc: LocalizationManager
    let character: GameCharacter
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Theme.goldGradient, lineWidth: 5)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
                .padding(8)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [3, 7]))
                .padding(14)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    CornerSeal(accent: accent)
                    Text(loc(character.realm.nameKey).uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .serif))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(character.rarity.label)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Theme.rarityGradient(character.rarity), in: Capsule())
                }
                .padding(.horizontal, 17)
                .padding(.top, 13)

                Spacer()

                HStack(alignment: .bottom, spacing: 6) {
                    Text(character.name.uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .serif))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                    Spacer()
                    CornerSeal(accent: accent)
                }
                .padding(.horizontal, 17)
                .padding(.bottom, 13)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CornerSeal: View {
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: 22, height: 22)
            Circle()
                .stroke(Theme.gold.opacity(0.9), lineWidth: 1)
                .frame(width: 20, height: 20)
            Image(systemName: "leaf.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(accent)
        }
    }
}

private struct PortalBackdrop: View {
    let color: Color
    let intensity: Double
    let beamActive: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [color.opacity(0.55 * intensity), .clear],
                                         center: .center, startRadius: 20, endRadius: 360))
                    .frame(width: 620, height: 620)
                    .blur(radius: 14)

                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .stroke(color.opacity((0.2 + Double(index) * 0.08) * intensity),
                                style: StrokeStyle(lineWidth: index == 0 ? 3 : 1,
                                                   dash: index.isMultiple(of: 2) ? [10, 18] : [3, 12]))
                        .frame(width: 230 + CGFloat(index) * 74,
                               height: 230 + CGFloat(index) * 74)
                        .rotationEffect(.degrees(t * (index.isMultiple(of: 2) ? 18 : -12)))
                        .scaleEffect(beamActive ? 1.03 : 0.82)
                }

                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [.clear, color.opacity(0.55 * intensity), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: beamActive ? 150 : 18, height: beamActive ? 680 : 80)
                    .blur(radius: beamActive ? 12 : 3)
                    .opacity(beamActive ? 1 : 0)

                ForEach(0..<18, id: \.self) { index in
                    let angle = Double(index) / 18 * 360 + t * 22
                    let distance = 120 + abs(sin(t * 1.7 + Double(index))) * 180
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index.isMultiple(of: 3) ? Theme.gold : color)
                        .frame(width: 3, height: 18 + CGFloat(index % 4) * 8)
                        .offset(y: -distance)
                        .rotationEffect(.degrees(angle))
                        .opacity(intensity * 0.7)
                }
            }
            .frame(width: 720, height: 720)
            .scaleEffect(0.84 + intensity * 0.16)
        }
    }
}
