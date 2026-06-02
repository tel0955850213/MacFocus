import Foundation

struct FocusSession: Codable, Identifiable, Hashable {
    var id = UUID()
    let date: Date
    let minutes: Int
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
}
