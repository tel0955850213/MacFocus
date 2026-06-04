import Foundation
import AppKit
import UserNotifications

/// Plays the completion sound and (optionally) posts a system notification when a
/// focus session ends. All calls are no-ops unless the matching setting is on.
enum Notifier {
    /// Call when a focus session finishes.
    @MainActor
    static func focusFinished(settings: SettingsStore, minutes: Int) {
        if settings.completionSound || settings.soundEffects {
            NSSound(named: "Glass")?.play()
        }
        if settings.systemNotifications {
            postBanner(title: "Focus complete", body: "You focused for \(minutes) minutes. Time for a break!")
        }
    }

    /// A short tap/feedback sound for UI actions (e.g. a gacha draw).
    @MainActor
    static func effect(settings: SettingsStore, named: String = "Pop") {
        guard settings.soundEffects else { return }
        NSSound(named: named)?.play()
    }

    private static func postBanner(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content, trigger: nil)
            center.add(request)
        }
    }
}
