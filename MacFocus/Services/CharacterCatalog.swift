import Foundation

/// Character catalog. Splash art is produced by scripts/gen_characters.sh via the
/// Codex gpt-image CLI; filenames match each character's `assetName` (placed in
/// Assets.xcassets/characters). `title` and `tagline` hold localization keys that
/// are resolved at display time (see LocalizationManager).
enum CharacterCatalog {
    static let all: [GameCharacter] = [
        GameCharacter(id: "char_aurora", name: "Aurora", title: "char.aurora.title",
                      rarity: .normal, assetName: "char_aurora", unlockHours: 0,
                      tagline: "char.aurora.tagline", swatchHex: 0x6E7488),
        GameCharacter(id: "char_vela", name: "Vela", title: "char.vela.title",
                      rarity: .normal, assetName: "char_vela", unlockHours: 0,
                      tagline: "char.vela.tagline", swatchHex: 0x5B6E88),
        GameCharacter(id: "char_lyra", name: "Lyra", title: "char.lyra.title",
                      rarity: .rare, assetName: "char_lyra", unlockHours: 0,
                      tagline: "char.lyra.tagline", swatchHex: 0x2D5DFF),
        GameCharacter(id: "char_seraphine", name: "Seraphine", title: "char.seraphine.title",
                      rarity: .rare, assetName: "char_seraphine", unlockHours: 0,
                      tagline: "char.seraphine.tagline", swatchHex: 0x3A7DFF),
        GameCharacter(id: "char_ember", name: "Ember", title: "char.ember.title",
                      rarity: .superRare, assetName: "char_ember", unlockHours: 0,
                      tagline: "char.ember.tagline", swatchHex: 0x7C4DFF),
        GameCharacter(id: "char_noctis", name: "Noctis", title: "char.noctis.title",
                      rarity: .superRare, assetName: "char_noctis", unlockHours: 0,
                      tagline: "char.noctis.tagline", swatchHex: 0xB94DFF),
        GameCharacter(id: "char_celestia", name: "Celestia", title: "char.celestia.title",
                      rarity: .ssr, assetName: "char_celestia", unlockHours: 10,
                      tagline: "char.celestia.tagline", swatchHex: 0xFF7A4D),
        GameCharacter(id: "char_aphrodite", name: "Aphrodite", title: "char.aphrodite.title",
                      rarity: .ssr, assetName: "char_aphrodite", unlockHours: 25,
                      tagline: "char.aphrodite.tagline", swatchHex: 0xFF4D8D),
    ]

    static func character(id: String) -> GameCharacter? {
        all.first { $0.id == id }
    }

    /// Characters obtainable from the gacha (excludes the focus-hours-only ones).
    static var gachaPool: [GameCharacter] {
        all.filter { $0.unlockHours == 0 }
    }

    /// Limited characters that only unlock once a focus-hours threshold is reached.
    static var timeGated: [GameCharacter] {
        all.filter { $0.unlockHours > 0 }
    }
}
