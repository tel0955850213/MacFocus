import SwiftUI
import Charts

struct StatsScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var loc: LocalizationManager

    private var daily: [(day: Date, minutes: Int)] {
        progress.sessions.dailyMinutes(lastDays: 7)
    }

    private var tagTotals: [(tag: String, minutes: Int)] {
        progress.sessions.minutesByTag(lastDays: 84)
            .map { (tag: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(loc("stats.title"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 190), spacing: 14)],
                          spacing: 14) {
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

                HeatmapView(sessions: progress.sessions,
                            dailyGoalMinutes: settings.dailyGoalMinutes)

                if !tagTotals.isEmpty {
                    TagBreakdownView(totals: tagTotals)
                }
            }
            .padding(32)
        }
    }
}

private struct TagBreakdownView: View {
    let totals: [(tag: String, minutes: Int)]
    @EnvironmentObject var loc: LocalizationManager

    private var maxMinutes: Int { max(1, totals.map(\.minutes).max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("stats.byTag"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ForEach(totals, id: \.tag) { item in
                VStack(spacing: 5) {
                    HStack {
                        Text(displayName(for: item.tag))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(item.minutes) \(loc("unit.min"))")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Theme.surfaceHi)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(Theme.heroGradient)
                                    .frame(width: proxy.size.width * CGFloat(item.minutes) / CGFloat(maxMinutes))
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func displayName(for tag: String) -> String {
        FocusTag(rawValue: tag).map { loc($0.labelKey) }
            ?? (tag == "untagged" ? loc("tag.untagged") : tag)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(16)
        .frame(minHeight: 104)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1))
    }
}
