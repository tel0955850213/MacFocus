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
    /// Localization key for the character's title (e.g. "char.ember.title").
    let title: String
    let rarity: Rarity
    /// Asset image name in Assets.xcassets/characters; nil ⇒ render placeholder.
    let assetName: String?
    /// Extra unlock condition: cumulative focus-hours threshold. 0 ⇒ gacha-only.
    let unlockHours: Double
    /// Localization key for the character's tagline.
    let tagline: String

    /// Theme color (used for the placeholder gradient when art is missing).
    var swatch: Color { Color(hex: swatchHex) }
    let swatchHex: UInt

    /// Idle animation style for the desktop companion — unique per character to
    /// echo her theme.
    var petMotion: PetMotion {
        switch id {
        case "char_aurora":    return .bobSway      // Dawn Ranger: light bob + sway
        case "char_vela":      return .dart         // Night Assassin: quick darting
        case "char_lyra":      return .spinSway     // Starsong Bard: melodic sway/spin
        case "char_seraphine": return .float        // Tide Sorceress: slow floating
        case "char_ember":     return .flicker      // Flame Mage: flame-like flicker/scale
        case "char_noctis":    return .breathe      // Shadow Queen: calm breathing + fade
        case "char_celestia":  return .glowPulse    // Celestial Swordmaiden: hover + glow pulse
        case "char_aphrodite": return .heartbeat    // Dawn Goddess: heartbeat rhythm
        default:               return .bobSway
        }
    }
}

/// Per-character idle animation: combines sine waves into a distinct rhythm.
enum PetMotion {
    case bobSway, dart, spinSway, float, flicker, breathe, glowPulse, heartbeat

    /// Compute the current offset/rotation/scale/opacity from elapsed seconds.
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
            let beat = pow(max(0, s(1.1)), 6)   // sharp heartbeat pulse
            return (0, s(2.2) * -4, 0, 1 + beat * 0.12, 1)
        }
    }
}
