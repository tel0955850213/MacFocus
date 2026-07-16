import Foundation

/// Character catalog. Splash art is produced by scripts/gen_characters.sh via the
/// Codex gpt-image CLI; filenames match each character's `assetName` (placed in
/// Assets.xcassets/characters). `title` and `tagline` hold localization keys that
/// are resolved at display time (see LocalizationManager).
enum CharacterCatalog {
    static let all: [GameCharacter] = [
        GameCharacter(id: "char_aurora", name: "Aurora", title: "char.aurora.title",
                      rarity: .normal, realm: .asterra, kind: .heroine,
                      assetName: "char_aurora", unlockHours: 0,
                      tagline: "char.aurora.tagline", swatchHex: 0x6E7488),
        GameCharacter(id: "char_vela", name: "Vela", title: "char.vela.title",
                      rarity: .normal, realm: .kharvane, kind: .heroine,
                      assetName: "char_vela", unlockHours: 0,
                      tagline: "char.vela.tagline", swatchHex: 0x5B6E88),
        GameCharacter(id: "char_lyra", name: "Lyra", title: "char.lyra.title",
                      rarity: .rare, realm: .elyrion, kind: .heroine,
                      assetName: "char_lyra", unlockHours: 0,
                      tagline: "char.lyra.tagline", swatchHex: 0x2D5DFF),
        GameCharacter(id: "char_seraphine", name: "Seraphine", title: "char.seraphine.title",
                      rarity: .rare, realm: .elyrion, kind: .heroine,
                      assetName: "char_seraphine", unlockHours: 0,
                      tagline: "char.seraphine.tagline", swatchHex: 0x3A7DFF),
        GameCharacter(id: "char_ember", name: "Ember", title: "char.ember.title",
                      rarity: .superRare, realm: .kharvane, kind: .heroine,
                      assetName: "char_ember", unlockHours: 0,
                      tagline: "char.ember.tagline", swatchHex: 0x7C4DFF),
        GameCharacter(id: "char_noctis", name: "Noctis", title: "char.noctis.title",
                      rarity: .superRare, realm: .elyrion, kind: .heroine,
                      assetName: "char_noctis", unlockHours: 0,
                      tagline: "char.noctis.tagline", swatchHex: 0xB94DFF),
        GameCharacter(id: "char_celestia", name: "Celestia", title: "char.celestia.title",
                      rarity: .ssr, realm: .asterra, kind: .heroine,
                      assetName: "char_celestia", unlockHours: 10,
                      tagline: "char.celestia.tagline", swatchHex: 0xFF7A4D),
        GameCharacter(id: "char_aphrodite", name: "Aphrodite", title: "char.aphrodite.title",
                      rarity: .ssr, realm: .asterra, kind: .heroine,
                      assetName: "char_aphrodite", unlockHours: 25,
                      tagline: "char.aphrodite.tagline", swatchHex: 0xFF4D8D),

        // Asterra — one heroine, one hero, and one Nokiri smallfolk.
        GameCharacter(id: "char_elyra", name: "Elyra", title: "char.elyra.title",
                      rarity: .rare, realm: .asterra, kind: .heroine,
                      assetName: "char_elyra", unlockHours: 0,
                      tagline: "char.elyra.tagline", swatchHex: 0xE8B84A),
        GameCharacter(id: "char_caelith", name: "Caelith", title: "char.caelith.title",
                      rarity: .rare, realm: .asterra, kind: .hero,
                      assetName: "char_caelith", unlockHours: 0,
                      tagline: "char.caelith.tagline", swatchHex: 0x78A8D8),
        GameCharacter(id: "char_miri", name: "Miri", title: "char.miri.title",
                      rarity: .normal, realm: .asterra, kind: .smallfolk,
                      assetName: "char_miri", unlockHours: 0,
                      tagline: "char.miri.tagline", swatchHex: 0xA6D98A),

        // Elyrion — dream singers, soul scribes, and a masked Nokiri seer.
        GameCharacter(id: "char_vespera", name: "Vespera", title: "char.vespera.title",
                      rarity: .rare, realm: .elyrion, kind: .heroine,
                      assetName: "char_vespera", unlockHours: 0,
                      tagline: "char.vespera.tagline", swatchHex: 0x8D86D8),
        GameCharacter(id: "char_orlan", name: "Orlan", title: "char.orlan.title",
                      rarity: .superRare, realm: .elyrion, kind: .hero,
                      assetName: "char_orlan", unlockHours: 0,
                      tagline: "char.orlan.tagline", swatchHex: 0x6EA7C8),
        GameCharacter(id: "char_pellin", name: "Pellin", title: "char.pellin.title",
                      rarity: .normal, realm: .elyrion, kind: .smallfolk,
                      assetName: "char_pellin", unlockHours: 0,
                      tagline: "char.pellin.tagline", swatchHex: 0xB58DE0),

        // Kharvane — oathblades, ash warlords, and a sparkpot-running Nokiri.
        GameCharacter(id: "char_kaedra", name: "Kaedra", title: "char.kaedra.title",
                      rarity: .superRare, realm: .kharvane, kind: .heroine,
                      assetName: "char_kaedra", unlockHours: 0,
                      tagline: "char.kaedra.tagline", swatchHex: 0xD85A4E),
        GameCharacter(id: "char_theron", name: "Theron", title: "char.theron.title",
                      rarity: .superRare, realm: .kharvane, kind: .hero,
                      assetName: "char_theron", unlockHours: 0,
                      tagline: "char.theron.tagline", swatchHex: 0x9D6558),
        GameCharacter(id: "char_brindle", name: "Brindle", title: "char.brindle.title",
                      rarity: .normal, realm: .kharvane, kind: .smallfolk,
                      assetName: "char_brindle", unlockHours: 0,
                      tagline: "char.brindle.tagline", swatchHex: 0xD58A4F),
    ]

    static func character(id: String) -> GameCharacter? {
        all.first { $0.id == id }
    }

    /// Characters obtainable from the gacha (excludes the focus-hours-only ones).
    static var gachaPool: [GameCharacter] {
        // Do not let an unfinished character art asset reach a real summon.
        // The character remains visible in the collection as locked content and
        // joins the pool automatically when its image set is bundled.
        all.filter { character in
            character.unlockHours == 0 &&
            (character.assetName.map(AssetLookup.exists) ?? false)
        }
    }

    /// Limited characters that only unlock once a focus-hours threshold is reached.
    static var timeGated: [GameCharacter] {
        all.filter { $0.unlockHours > 0 }
    }
}
