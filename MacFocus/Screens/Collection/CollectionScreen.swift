import SwiftUI

struct CollectionScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @State private var selected: GameCharacter?

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("英雄圖鑑")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(progress.unlockedIds.count) / \(CharacterCatalog.all.count) 已解鎖")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(CharacterCatalog.all) { c in
                        CharacterCard(character: c,
                                      unlocked: progress.isUnlocked(c),
                                      isPartner: progress.partnerId == c.id) {
                            if progress.isUnlocked(c) { selected = c }
                        }
                    }
                }
            }
            .padding(32)
        }
        .sheet(item: $selected) { c in
            CharacterDetailSheet(character: c)
                .environmentObject(progress)
        }
    }
}

struct CharacterDetailSheet: View {
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.dismiss) var dismiss
    let character: GameCharacter

    var body: some View {
        VStack(spacing: 16) {
            CharacterPortrait(character: character)
                .frame(width: 240, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.rarityGradient(character.rarity), lineWidth: 3))

            HStack(spacing: 8) {
                RarityBadge(rarity: character.rarity)
                Text(character.name)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(character.title)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.primaryHi)
            Text(character.tagline)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: progress.partnerId == character.id ? "目前的夥伴" : "設為專注夥伴",
                          systemImage: "star.fill",
                          enabled: progress.partnerId != character.id) {
                progress.setPartner(character)
                dismiss()
            }
            .frame(maxWidth: 240)

            Button("關閉") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)
        }
        .padding(28)
        .frame(width: 340)
        .background(Theme.bg)
    }
}
