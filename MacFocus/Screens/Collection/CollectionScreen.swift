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

                ForEach(Realm.allCases) { realm in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 9) {
                            Image(systemName: realm.icon)
                                .foregroundStyle(Color(hex: realm.accentHex))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc(realm.nameKey))
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(loc(realm.loreKey))
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(CharacterCatalog.all.filter { $0.realm == realm }) { c in
                                CharacterCard(character: c,
                                              unlocked: progress.isUnlocked(c),
                                              isPartner: progress.partnerId == c.id) {
                                    if progress.isUnlocked(c) { selected = c }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Theme.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
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

    private var alternateAssetName: String? {
        guard let base = character.assetName else { return nil }
        let name = "\(base)_alt"
        return AssetLookup.exists(name) ? name : nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
            CharacterPortrait(character: character,
                              assetNameOverride: progress.displayAssetName(for: character))
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
            Label(loc(character.realm.nameKey), systemImage: character.realm.icon)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: character.realm.accentHex))
            Text(loc(character.tagline))
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            BondMeter(character: character)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))

            BondUnlockTimeline(character: character)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))

            if progress.bondLevel(for: character) >= 7, alternateAssetName != nil {
                Toggle(isOn: Binding(
                    get: { progress.usesAlternatePose(for: character) },
                    set: { progress.setUsesAlternatePose($0, for: character) }
                )) {
                    Label(loc("bond.useAlternatePose"), systemImage: "rectangle.on.rectangle")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .toggleStyle(.switch)
                .tint(Theme.primaryHi)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            } else if progress.bondLevel(for: character) < 7 {
                Label(loc("bond.poseLocked"), systemImage: "lock.fill")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            }

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
        }
        .background(Theme.bg)
    }
}
