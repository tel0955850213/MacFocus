import Foundation

enum FocusTag: String, CaseIterable, Identifiable {
    case work
    case study
    case create

    var id: String { rawValue }
    var labelKey: String { "tag.\(rawValue)" }
}

struct FocusSession: Codable, Identifiable, Hashable {
    var id = UUID()
    let date: Date
    let minutes: Int
    /// Optional session label (Work/Study/…). Optional ⇒ sessions saved by older
    /// builds decode as nil and show as "untagged".
    var tag: String? = nil
}

extension Array where Element == FocusSession {
    /// 某一天的總專注分鐘數。
    func minutes(on day: Date, calendar: Calendar = .current) -> Int {
        filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.minutes }
    }

    /// 過去 n 天(含今天)的每日分鐘數,由舊到新。
    func dailyMinutes(lastDays n: Int, calendar: Calendar = .current) -> [(day: Date, minutes: Int)] {
        let today = calendar.startOfDay(for: Date())
        return (0..<n).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return (day, minutes(on: day, calendar: calendar))
        }
    }

    /// Sum minutes by tag for the requested recent window. Nil tags are grouped
    /// under `untagged` so older sessions remain visible after the migration.
    func minutesByTag(lastDays n: Int, calendar: Calendar = .current) -> [String: Int] {
        let earliest = calendar.date(byAdding: .day, value: -(n - 1), to: calendar.startOfDay(for: Date()))!
        return reduce(into: [:]) { totals, session in
            guard session.date >= earliest else { return }
            totals[session.tag ?? "untagged", default: 0] += session.minutes
        }
    }
}
