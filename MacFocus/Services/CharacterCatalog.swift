import Foundation

/// 角色目錄 — 立繪素材由 scripts/gen_characters.sh 用 Codex gpt-image-2 產出,
/// 檔名對應每個角色的 `assetName`(放進 Assets.xcassets/characters)。
enum CharacterCatalog {
    static let all: [GameCharacter] = [
        GameCharacter(id: "char_aurora", name: "Aurora", title: "晨曦遊俠",
                      rarity: .normal, assetName: "char_aurora", unlockHours: 0,
                      tagline: "第一道破曉的光,陪你開始專注。", swatchHex: 0x6E7488),
        GameCharacter(id: "char_vela", name: "Vela", title: "夜風刺客",
                      rarity: .normal, assetName: "char_vela", unlockHours: 0,
                      tagline: "安靜俐落,專注時最好的搭檔。", swatchHex: 0x5B6E88),
        GameCharacter(id: "char_lyra", name: "Lyra", title: "星詠吟遊者",
                      rarity: .rare, assetName: "char_lyra", unlockHours: 0,
                      tagline: "用旋律幫你進入心流。", swatchHex: 0x2D5DFF),
        GameCharacter(id: "char_seraphine", name: "Seraphine", title: "潮汐術士",
                      rarity: .rare, assetName: "char_seraphine", unlockHours: 0,
                      tagline: "如潮水般綿長的專注力。", swatchHex: 0x3A7DFF),
        GameCharacter(id: "char_ember", name: "Ember", title: "烈焰法師",
                      rarity: .superRare, assetName: "char_ember", unlockHours: 0,
                      tagline: "點燃你的鬥志,絕不熄滅。", swatchHex: 0x7C4DFF),
        GameCharacter(id: "char_noctis", name: "Noctis", title: "暗影女王",
                      rarity: .superRare, assetName: "char_noctis", unlockHours: 0,
                      tagline: "掌控時間,如同掌控暗影。", swatchHex: 0xB94DFF),
        GameCharacter(id: "char_celestia", name: "Celestia", title: "天界執劍者",
                      rarity: .ssr, assetName: "char_celestia", unlockHours: 10,
                      tagline: "累積 10 小時專注才能召喚的傳說。", swatchHex: 0xFF7A4D),
        GameCharacter(id: "char_aphrodite", name: "Aphrodite", title: "黎明女神",
                      rarity: .ssr, assetName: "char_aphrodite", unlockHours: 25,
                      tagline: "25 小時的鍛鍊,只為與女神相遇。", swatchHex: 0xFF4D8D),
    ]

    static func character(id: String) -> GameCharacter? {
        all.first { $0.id == id }
    }

    /// 可透過抽卡獲得的角色(排除純時數解鎖的限定角)。
    static var gachaPool: [GameCharacter] {
        all.filter { $0.unlockHours == 0 }
    }

    /// 達到時數門檻才會解鎖的限定角色。
    static var timeGated: [GameCharacter] {
        all.filter { $0.unlockHours > 0 }
    }
}
