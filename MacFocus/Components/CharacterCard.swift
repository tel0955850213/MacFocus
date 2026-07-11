import SwiftUI

/// Splash-art loader: shows the asset (top-aligned crop so the head/face stays
/// visible) when present, otherwise a placeholder gradient.
struct CharacterPortrait: View {
    let character: GameCharacter
    var locked: Bool = false
    /// Uses an unlocked alternate pose when supplied; defaults to the base art.
    var assetNameOverride: String? = nil
    /// Alignment used when a tall image fills the frame; defaults to top (show face).
    var fillAlignment: Alignment = .top

    var body: some View {
        Color.clear
            .overlay(alignment: fillAlignment) {
                if let name = assetNameOverride ?? character.assetName, NSImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(colors: [character.swatch, character.swatch.opacity(0.4)],
                                   startPoint: .top, endPoint: .bottom)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.35)))
                }
            }
            .clipped()
        .overlay {
            if locked {
                ZStack {
                    Rectangle().fill(.black.opacity(0.55))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30)).foregroundStyle(.white.opacity(0.85))
                }
            }
        }
    }
}

struct CharacterCard: View {
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var progress: ProgressStore
    let character: GameCharacter
    var unlocked: Bool
    var isPartner: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            VStack(spacing: 0) {
                CharacterPortrait(character: character, locked: !unlocked)
                    .frame(height: 180)
                    .clipped()
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(unlocked ? character.name : loc("card.unknown"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        RarityBadge(rarity: character.rarity)
                    }
                    Text(unlocked ? loc(character.title) : loc("card.locked"))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    if unlocked {
                        HStack(spacing: 4) {
                            Text(loc(character.realm.nameKey))
                            Text("·")
                            Text(loc(character.kind.labelKey))
                        }
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: character.realm.accentHex))

                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                            Text(String(format: loc("bond.level"), progress.bondLevel(for: character)))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Theme.accent)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isPartner ? Theme.gold : Color.white.opacity(0.08),
                            lineWidth: isPartner ? 3 : 1))
            .shadow(color: character.rarity == .ssr ? Theme.gold.opacity(0.4) : .black.opacity(0.3),
                    radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct RarityBadge: View {
    let rarity: Rarity
    var body: some View {
        Text(rarity.label)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Theme.rarityGradient(rarity), in: Capsule())
    }
}
