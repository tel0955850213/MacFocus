import SwiftUI

struct StreakFlame: View {
    let days: Int
    @State private var flicker = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.gold, Theme.accent],
                                   startPoint: .top, endPoint: .bottom))
                .scaleEffect(flicker ? 1.12 : 0.95)
                .shadow(color: Theme.accent.opacity(0.7), radius: flicker ? 10 : 4)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(days)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("天連續")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.accent.opacity(0.3), lineWidth: 1))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { flicker = true }
        }
    }
}
