import Foundation
import SwiftUI

/// User-configurable preferences, persisted in UserDefaults. Timer durations are
/// mirrored into `TimerEngine` when they change (see `MacFocusApp`).
@MainActor
final class SettingsStore: ObservableObject {
    @Published var focusMinutes: Int          { didSet { save("focusMinutes", focusMinutes) } }
    @Published var shortBreakMinutes: Int     { didSet { save("shortBreakMinutes", shortBreakMinutes) } }
    @Published var longBreakMinutes: Int      { didSet { save("longBreakMinutes", longBreakMinutes) } }
    @Published var roundsBeforeLongBreak: Int { didSet { save("roundsBeforeLongBreak", roundsBeforeLongBreak) } }
    @Published var dailyGoalMinutes: Int      { didSet { save("dailyGoalMinutes", dailyGoalMinutes) } }

    @Published var completionSound: Bool      { didSet { save("completionSound", completionSound) } }
    @Published var systemNotifications: Bool  { didSet { save("systemNotifications", systemNotifications) } }
    @Published var soundEffects: Bool         { didSet { save("soundEffects", soundEffects) } }

    private let d = UserDefaults.standard
    private static let prefix = "macfocus.settings."

    init() {
        func intOr(_ key: String, _ fallback: Int) -> Int {
            let v = UserDefaults.standard.integer(forKey: Self.prefix + key)
            return v == 0 ? fallback : v
        }
        func boolOr(_ key: String, _ fallback: Bool) -> Bool {
            UserDefaults.standard.object(forKey: Self.prefix + key) as? Bool ?? fallback
        }
        focusMinutes          = intOr("focusMinutes", 25)
        shortBreakMinutes     = intOr("shortBreakMinutes", 5)
        longBreakMinutes      = intOr("longBreakMinutes", 15)
        roundsBeforeLongBreak = intOr("roundsBeforeLongBreak", 4)
        dailyGoalMinutes      = intOr("dailyGoalMinutes", 120)
        completionSound       = boolOr("completionSound", true)
        systemNotifications   = boolOr("systemNotifications", false)
        soundEffects          = boolOr("soundEffects", true)
    }

    private func save(_ key: String, _ value: Any) {
        d.set(value, forKey: Self.prefix + key)
    }
}
