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

    @Published var showMenuBarTimer: Bool     { didSet { save("showMenuBarTimer", showMenuBarTimer) } }
    @Published var hideDockIcon: Bool         { didSet { save("hideDockIcon", hideDockIcon) } }
    @Published var launchAtLogin: Bool        { didSet { save("launchAtLogin", launchAtLogin) } }
    @Published var lastFocusTag: String?      { didSet { saveOptionalString("lastFocusTag", lastFocusTag) } }
    @Published var customTags: [String]       { didSet { save("customTags", customTags) } }
    @Published var ambientSound: String       { didSet { save("ambientSound", ambientSound) } }
    @Published var ambientVolume: Double      { didSet { save("ambientVolume", ambientVolume) } }

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
        showMenuBarTimer      = boolOr("showMenuBarTimer", true)
        hideDockIcon          = boolOr("hideDockIcon", false)
        launchAtLogin         = boolOr("launchAtLogin", false)
        lastFocusTag          = UserDefaults.standard.string(forKey: Self.prefix + "lastFocusTag")
        customTags            = UserDefaults.standard.stringArray(forKey: Self.prefix + "customTags") ?? []
        ambientSound          = UserDefaults.standard.string(forKey: Self.prefix + "ambientSound") ?? AmbientSound.none.rawValue
        ambientVolume         = UserDefaults.standard.object(forKey: Self.prefix + "ambientVolume") as? Double ?? 0.6
    }

    private func save(_ key: String, _ value: Any) {
        d.set(value, forKey: Self.prefix + key)
    }

    private func saveOptionalString(_ key: String, _ value: String?) {
        guard let value else {
            d.removeObject(forKey: Self.prefix + key)
            return
        }
        d.set(value, forKey: Self.prefix + key)
    }

    func addCustomTag(_ name: String) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              !FocusTag.allCases.map(\.rawValue).contains(cleaned.lowercased()),
              !customTags.contains(where: { $0.localizedCaseInsensitiveCompare(cleaned) == .orderedSame })
        else { return }
        customTags.append(cleaned)
    }

    func removeCustomTag(_ name: String) {
        customTags.removeAll { $0 == name }
        if lastFocusTag == name { lastFocusTag = nil }
    }
}
