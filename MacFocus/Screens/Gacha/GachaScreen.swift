#if os(macOS)
import AppKit
#endif
import SwiftUI

/// A mouse-driven summoning machine. The player physically pulls the sealed card
/// out of the gate; a click alone never spends currency.
struct GachaScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var loc: LocalizationManager

    @State private var cardOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isSummoning = false
    @State private var cardOpacity = 1.0
    @State private var cardScale = 1.0
    @State private var gateFlash = false
    @State private var hoveringCard = false

    private let pullThreshold: CGFloat = 118
    private var canDraw: Bool { progress.coins >= progress.drawCost }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gateBackground(size: geometry.size)

                LinearGradient(
                    colors: [.black.opacity(0.52), .clear, .black.opacity(0.48)],
                    startPoint: .top,
                    endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                topBar
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                summonCard(in: geometry.size)

                rarityOdds
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(22)

#if DEBUG
                if !ProcessInfo.processInfo.arguments.contains("--screenshot-mode") {
                    Button(loc("gacha.debugGrant")) { progress._debugGrant(coins: 500) }
                        .accessibilityIdentifier("debug-grant-coins")
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.48), in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(22)
                }
#endif

                Color.white
                    .opacity(gateFlash ? 0.86 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .clipped()
        }
    }

    private func gateBackground(size: CGSize) -> some View {
        Image("summon_gate")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .scaleEffect(isSummoning ? 1.04 : 1)
            .brightness(isDragging ? dragProgress * 0.08 : 0)
            .animation(.easeInOut(duration: 0.35), value: isSummoning)
            .clipped()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(loc("gacha.title"))
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                Text(isSummoning ? loc("gacha.opening") : loc("gacha.ready"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isSummoning ? Theme.gold : .white.opacity(0.65))
            }

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                Text(String(format: loc("gacha.coins"), progress.coins))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("coin-balance")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.5), in: Capsule())
            .overlay(Capsule().stroke(Theme.gold.opacity(0.45), lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func summonCard(in size: CGSize) -> some View {
        // Keep the sealed card dominant on wide Mac windows, matching the
        // physical-card composition of the reference instead of reading as a
        // small button beneath the gate artwork.
        let cardWidth = min(max(size.width * 0.34, 210), 285)
        let cardHeight = cardWidth * 1.5

        return TimelineView(.animation) { timeline in
            let idle = sin(timeline.date.timeIntervalSinceReferenceDate * 2.2)
            let idleLift = isDragging || isSummoning ? 0 : idle * 3

            ZStack {
                Image("summon_card_back")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cardWidth, height: cardHeight)
                    .shadow(color: Theme.gold.opacity(0.45 + dragProgress * 0.5),
                            radius: 18 + dragProgress * 24)

                if !canDraw {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.58))
                        .frame(width: cardWidth * 0.86, height: cardHeight * 0.9)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(cardScale + dragProgress * 0.025)
            .rotationEffect(.degrees(Double(cardOffset.width / 24)))
            .offset(x: cardOffset.width * 0.32,
                    y: cardOffset.height + idleLift)
            .opacity(cardOpacity)
            .overlay(alignment: .bottom) {
                if canDraw && !isSummoning && !isDragging {
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .offset(y: 25 + idle * 4)
                        .shadow(color: .black, radius: 4)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .gesture(pullGesture)
            .onHover { hovering in
                hoveringCard = hovering
                #if os(macOS)
                if canDraw && !isSummoning {
                    hovering ? NSCursor.openHand.set() : NSCursor.arrow.set()
                }
                #endif
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("summon-card")
            .accessibilityLabel(Text(loc("gacha.hint")))
            .accessibilityAction {
                if canDraw { finishSummon() }
            }
            .position(x: size.width * 0.5, y: size.height * 0.63)
        }
    }

    private var pullGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard canDraw, !isSummoning else { return }
                isDragging = true
                #if os(macOS)
                NSCursor.closedHand.set()
                #endif
                cardOffset = CGSize(
                    width: value.translation.width,
                    height: max(-14, value.translation.height))
            }
            .onEnded { value in
                guard canDraw, !isSummoning else { return }
                isDragging = false
                #if os(macOS)
                hoveringCard ? NSCursor.openHand.set() : NSCursor.arrow.set()
                #endif

                if value.translation.height >= pullThreshold {
                    finishSummon()
                } else {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.66)) {
                        cardOffset = .zero
                    }
                }
            }
    }

    private var dragProgress: CGFloat {
        min(1, max(0, cardOffset.height / pullThreshold))
    }

    private func finishSummon() {
        guard canDraw, !isSummoning else { return }
        isSummoning = true
        isDragging = false
        Notifier.effect(settings: settings)

        withAnimation(.easeIn(duration: 0.34)) {
            cardOffset = CGSize(width: cardOffset.width * 0.2, height: 430)
            cardScale = 0.72
            cardOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.16).delay(0.28)) {
            gateFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            _ = progress.drawGacha()
            resetMachine()
        }
    }

    private func resetMachine() {
        cardOffset = .zero
        cardScale = 1
        cardOpacity = 1
        gateFlash = false
        isSummoning = false
    }

    private var rarityOdds: some View {
        HStack(spacing: 8) {
            ForEach(Rarity.allCases.reversed(), id: \.self) { rarity in
                let total = CharacterCatalog.gachaPool.reduce(0.0) { $0 + $1.rarity.drawWeight }
                let weight = CharacterCatalog.gachaPool
                    .filter { $0.rarity == rarity }
                    .reduce(0.0) { $0 + $1.rarity.drawWeight }

                HStack(spacing: 4) {
                    RarityBadge(rarity: rarity)
                    Text(total > 0 ? String(format: "%.0f%%", weight / total * 100) : "—")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.gold.opacity(0.3), lineWidth: 1))
    }
}
