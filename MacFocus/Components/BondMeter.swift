import SwiftUI

/// Visualizes the long-term relationship progress with a companion.
struct BondMeter: View {
    let character: GameCharacter
    var compact = false
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager

    private var level: Int { progress.bondLevel(for: character) }
    private var progressValue: Double { progress.bondProgress(for: character) }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: compact ? 11 : 13))
                Text(String(format: loc("bond.level"), level))
                    .font(.system(size: compact ? 11 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if !compact {
                    Text("\(progress.bondMinutes(for: character)) \(loc("unit.min"))")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            ProgressView(value: progressValue)
                .tint(Theme.accent)
                .scaleEffect(y: compact ? 0.7 : 1)
            if !compact {
                Text(nextText)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var nextText: String {
        if let remaining = progress.bondMinutesToNextLevel(for: character) {
            return String(format: loc("bond.next"), remaining)
        }
        return loc("bond.max")
    }
}

struct BondUnlockTimeline: View {
    let character: GameCharacter
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager

    private let milestones = [2, 4, 6, 7, 8, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc("bond.unlocks"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            ForEach(milestones, id: \.self) { milestone in
                let unlocked = progress.bondLevel(for: character) >= milestone
                HStack(spacing: 10) {
                    Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(unlocked ? Theme.mint : Theme.textSecondary)
                        .frame(width: 18)
                    Text(String(format: loc("bond.milestone"), milestone))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(unlocked ? .white : Theme.textSecondary)
                    Spacer()
                    Text(loc(milestone == 7 ? "bond.reward.pose" : "bond.reward.lines"))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(unlocked ? Theme.primaryHi : Theme.textSecondary.opacity(0.7))
                }
            }
        }
    }
}
