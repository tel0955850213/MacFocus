import SwiftUI

/// Compact daily-goal progress pill: a ring showing today's focus minutes vs. the
/// user's daily goal, plus a "X / Y min" label (or a "done" badge when reached).
struct DailyGoalRing: View {
    @EnvironmentObject var loc: LocalizationManager
    let todayMinutes: Int
    let goalMinutes: Int

    private var fraction: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(1, Double(todayMinutes) / Double(goalMinutes))
    }
    private var reached: Bool { goalMinutes > 0 && todayMinutes >= goalMinutes }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().stroke(Theme.surfaceHi, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(reached ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.heroGradient),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: fraction)
                Image(systemName: reached ? "checkmark" : "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(reached ? Theme.gold : Theme.primaryHi)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(loc("daily.goal"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Text(reached ? loc("daily.done")
                             : String(format: loc("daily.progress"), todayMinutes, goalMinutes))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.primary.opacity(0.25), lineWidth: 1))
    }
}
