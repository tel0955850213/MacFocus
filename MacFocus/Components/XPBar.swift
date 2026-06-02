import SwiftUI

struct XPBar: View {
    let level: Int
    let progress: Double      // 0...1
    let xpInto: Int
    let xpSpan: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Lv. \(level)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.gold)
                Spacer()
                Text("\(xpInto) / \(xpSpan) XP")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceHi)
                    Capsule()
                        .fill(Theme.goldGradient)
                        .frame(width: max(8, geo.size.width * progress))
                        .shadow(color: Theme.gold.opacity(0.6), radius: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 12)
        }
    }
}
