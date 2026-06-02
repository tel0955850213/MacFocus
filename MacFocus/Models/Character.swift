import SwiftUI

enum Rarity: Int, Codable, CaseIterable, Comparable {
    case normal = 0      // N
    case rare = 1        // R
    case superRare = 2   // SR
    case ssr = 3         // SSR

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .normal: return "N"
        case .rare: return "R"
        case .superRare: return "SR"
        case .ssr: return "SSR"
        }
    }

    /// Relative weight for the gacha draw — rarer is much less likely.
    var drawWeight: Double {
        switch self {
        case .normal: return 60
        case .rare: return 28
        case .superRare: return 10
        case .ssr: return 2
        }
    }
}

struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let title: String           // 稱號,例如 "烈焰法師"
    let rarity: Rarity
    /// Asset image name in Assets.xcassets/characters; nil ⇒ render placeholder.
    let assetName: String?
    /// 額外解鎖條件:累積專注時數門檻(小時)。0 ⇒ 只能靠抽卡。
    let unlockHours: Double
    let tagline: String

    /// 主題色(立繪缺席時的佔位漸層用)
    var swatch: Color { Color(hex: swatchHex) }
    let swatchHex: UInt

    /// 桌面夥伴的待機動畫風格 — 每個角色都不一樣,呼應她的世界觀。
    var petMotion: PetMotion {
        switch id {
        case "char_aurora":    return .bobSway      // 破曉遊俠:輕快上下 + 左右搖
        case "char_vela":      return .dart         // 暗夜刺客:快速閃動
        case "char_lyra":      return .spinSway     // 星詩人:旋律般擺動旋轉
        case "char_seraphine": return .float        // 潮汐術師:緩慢漂浮
        case "char_ember":     return .flicker      // 烈焰法師:火焰跳動縮放
        case "char_noctis":    return .breathe      // 暗影女王:沉穩呼吸 + 淡入淡出
        case "char_celestia":  return .glowPulse    // 聖光劍姬:浮空 + 發光脈動
        case "char_aphrodite": return .heartbeat    // 黎明女神:心跳般律動
        default:               return .bobSway
        }
    }
}

/// 不同角色的待機動畫:用連續的正弦波組合出各自獨特的律動。
enum PetMotion {
    case bobSway, dart, spinSway, float, flicker, breathe, glowPulse, heartbeat

    /// 依經過秒數算出當下的位移/旋轉/縮放/透明度。
    func frame(at t: Double) -> (dx: Double, dy: Double, rot: Double, scale: Double, opacity: Double) {
        func s(_ period: Double, _ phase: Double = 0) -> Double { sin(t * 2 * .pi / period + phase) }
        switch self {
        case .bobSway:   return (s(2.4) * 8, s(1.3) * -6, s(2.4) * 3, 1, 1)
        case .dart:      return (s(0.9) * 16, abs(s(1.8)) * -5, s(0.9) * 6, 1, 1)
        case .spinSway:  return (s(2.0) * 5, s(1.6) * -5, s(3.2) * 10, 1 + s(2.0) * 0.03, 1)
        case .float:     return (s(3.0) * 4, s(2.6) * -10, s(4.0) * 2, 1, 1)
        case .flicker:   return (s(0.7) * 2, s(0.5) * -3, 0, 1 + abs(s(0.6)) * 0.08, 0.92 + abs(s(0.4)) * 0.08)
        case .breathe:   return (0, s(3.4) * -4, s(5.0) * 2, 1 + s(3.4) * 0.04, 0.85 + (s(3.4) + 1) / 2 * 0.15)
        case .glowPulse: return (0, s(2.2) * -7, s(4.4) * 3, 1 + abs(s(2.2)) * 0.05, 1)
        case .heartbeat:
            let beat = pow(max(0, s(1.1)), 6)   // 尖銳的心跳脈衝
            return (0, s(2.2) * -4, 0, 1 + beat * 0.12, 1)
        }
    }
}
