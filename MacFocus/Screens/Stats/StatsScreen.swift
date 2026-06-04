import SwiftUI
import Charts

struct StatsScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager

    private var daily: [(day: Date, minutes: Int)] {
        progress.sessions.dailyMinutes(lastDays: 7)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(loc("stats.title"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    StatTile(value: String(format: "%.1f", progress.totalFocusHours),
                             unit: loc("unit.hours"), label: loc("stats.totalFocus"), color: Theme.primaryHi)
                    StatTile(value: "\(progress.currentStreak)", unit: loc("unit.days"), label: loc("stats.streak"), color: Theme.accent)
                    StatTile(value: "\(progress.bestStreak)", unit: loc("unit.days"), label: loc("stats.best"), color: Theme.gold)
                    StatTile(value: "\(progress.level)", unit: "Lv", label: loc("stats.level"), color: Theme.mint)
                }

                Text(loc("stats.last7"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Chart(daily, id: \.day) { item in
                    BarMark(
                        x: .value(loc("axis.day"), item.day, unit: .day),
                        y: .value(loc("axis.minutes"), item.minutes))
                    .foregroundStyle(Theme.heroGradient)
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.surfaceHi)
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 240)
                .padding(16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(32)
        }
    }
}

struct StatTile: View {
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1))
    }
}
