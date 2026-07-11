import SwiftUI

/// GitHub-style 12-week focus calendar. It uses ordinary SwiftUI rectangles
/// rather than Charts because calendar alignment matters more than axes here.
struct HeatmapView: View {
    let sessions: [FocusSession]
    let dailyGoalMinutes: Int
    @EnvironmentObject var loc: LocalizationManager

    private let calendar = Calendar.current

    private var weeks: [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let weekdayOffset = (calendar.component(.weekday, from: today) - calendar.firstWeekday + 7) % 7
        let currentWeekStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: today)!
        let start = calendar.date(byAdding: .day, value: -77, to: currentWeekStart)!
        return (0..<12).map { week in
            (0..<7).map { day in
                calendar.date(byAdding: .day, value: week * 7 + day, to: start)!
            }
        }
    }

    private var dailyTotals: [Date: Int] {
        sessions.reduce(into: [:]) { totals, session in
            let day = calendar.startOfDay(for: session.date)
            totals[day, default: 0] += session.minutes
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("stats.heatmap"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 7) {
                weekdayLabels
                HStack(spacing: 4) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 4) {
                            ForEach(week, id: \.self) { day in
                                cell(for: day)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 5) {
                Text(loc("stats.less"))
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(forFraction: Double(level) / 4))
                        .frame(width: 12, height: 12)
                }
                Text(loc("stats.more"))
            }
            .font(.system(size: 11, design: .rounded))
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private var weekdayLabels: some View {
        VStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { offset in
                let weekday = (calendar.firstWeekday - 1 + offset) % 7
                Text(offset.isMultiple(of: 2) ? calendar.veryShortWeekdaySymbols[weekday] : "")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 12, height: 12)
            }
        }
    }

    private func cell(for day: Date) -> some View {
        let minutes = dailyTotals[calendar.startOfDay(for: day), default: 0]
        let fraction = min(1, Double(minutes) / Double(max(1, dailyGoalMinutes)))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: loc.resolved == .zhHant ? "zh_Hant" : "en_US")
        formatter.dateStyle = .medium

        return RoundedRectangle(cornerRadius: 3)
            .fill(color(forFraction: fraction))
            .frame(width: 12, height: 12)
            .help("\(formatter.string(from: day)): \(minutes) \(loc("unit.min"))")
            .accessibilityLabel("\(formatter.string(from: day)), \(minutes) \(loc("unit.min"))")
    }

    private func color(forFraction fraction: Double) -> Color {
        switch fraction {
        case 0: return Theme.surfaceHi.opacity(0.55)
        case ..<0.25: return Theme.primaryHi.opacity(0.25)
        case ..<0.5: return Theme.primaryHi.opacity(0.45)
        case ..<0.75: return Theme.primaryHi.opacity(0.7)
        default: return Theme.primaryHi
        }
    }
}
