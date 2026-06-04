import SwiftUI

struct CollectionScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager
    @State private var selected: GameCharacter?

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(loc("collection.title"))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: loc("collection.unlocked"),
                                progress.unlockedIds.count, CharacterCatalog.all.count))
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
                .environmentObject(loc)
        }
    }
}

struct CharacterDetailSheet: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager
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
            Text(loc(character.title))
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.primaryHi)
            Text(loc(character.tagline))
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: progress.partnerId == character.id ? loc("collection.current") : loc("collection.setPartner"),
                          systemImage: "star.fill",
                          enabled: progress.partnerId != character.id) {
                progress.setPartner(character)
                dismiss()
            }
            .frame(maxWidth: 240)

            Button(loc("common.close")) { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)
        }
        .padding(28)
        .frame(width: 340)
        .background(Theme.bg)
    }
}
