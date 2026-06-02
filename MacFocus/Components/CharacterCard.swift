import SwiftUI

/// 立繪載入:有素材就顯示圖(裁切對齊頂部,確保露出頭/臉),否則畫佔位漸層。
struct CharacterPortrait: View {
    let character: GameCharacter
    var locked: Bool = false
    /// 高立繪填滿時的對齊方向,預設頂部(露臉)。
    var fillAlignment: Alignment = .top

    var body: some View {
        Color.clear
            .overlay(alignment: fillAlignment) {
                if let name = character.assetName, NSImage(named: name) != nil {
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
                        Text(unlocked ? character.name : "？？？")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        RarityBadge(rarity: character.rarity)
                    }
                    Text(unlocked ? character.title : "尚未解鎖")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
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
