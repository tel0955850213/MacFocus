import SwiftUI

enum Theme {
    // Brand palette — saturated game-card colors grounded by a cool slate UI.
    static let bg = Color(hex: 0x101A26)
    static let surface = Color(hex: 0x1B2A3A)
    static let surfaceHi = Color(hex: 0x2B4053)
    static let primary = Color(hex: 0x4E7BFF)
    static let primaryHi = Color(hex: 0x88C8FF)
    static let accent = Color(hex: 0xFF5F8F)
    static let gold = Color(hex: 0xFFD15C)
    static let mint = Color(hex: 0xC6F36D)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)

    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: 0x17283B), Color(hex: 0x0D151F)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let sidebarGradient = LinearGradient(
        colors: [Color(hex: 0x1C3045), Color(hex: 0x142231)],
        startPoint: .top, endPoint: .bottom)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x4E7BFF), Color(hex: 0xFF5F8F)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xFFF19A), Color(hex: 0xFFB64D)],
        startPoint: .top, endPoint: .bottom)

    static func rarityGradient(_ r: Rarity) -> LinearGradient {
        switch r {
        case .normal: return LinearGradient(colors: [Color(hex: 0x9AA0B5), Color(hex: 0x6E7488)], startPoint: .top, endPoint: .bottom)
        case .rare: return LinearGradient(colors: [Color(hex: 0x4D9DFF), Color(hex: 0x2D5DFF)], startPoint: .top, endPoint: .bottom)
        case .superRare: return LinearGradient(colors: [Color(hex: 0xB94DFF), Color(hex: 0x7C4DFF)], startPoint: .top, endPoint: .bottom)
        case .ssr: return LinearGradient(colors: [Color(hex: 0xFFE08A), Color(hex: 0xFF7A4D), Color(hex: 0xFF4D8D)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha)
    }
}
