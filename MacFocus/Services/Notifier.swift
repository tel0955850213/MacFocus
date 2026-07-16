import Foundation
#if os(macOS)
import AppKit
#else
import AudioToolbox
#endif
import UserNotifications

/// Plays the completion sound and (optionally) posts a system notification when a
/// focus session ends. All calls are no-ops unless the matching setting is on.
enum Notifier {
    /// Call when a focus session finishes.
    @MainActor
    static func focusFinished(settings: SettingsStore, loc: LocalizationManager, minutes: Int) {
        if settings.completionSound || settings.soundEffects {
            #if os(macOS)
            NSSound(named: "Glass")?.play()
            #else
            AudioServicesPlaySystemSound(1007)
            #endif
        }
        if settings.systemNotifications {
            postBanner(title: loc("notify.focusComplete"),
                       body: String(format: loc("notify.focusBody"), minutes))
        }
    }

    /// Ask for notification permission when the user enables the setting, not at
    /// the end of a focus session. This keeps the reward moment interruption-free.
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// A short tap/feedback sound for UI actions (e.g. a gacha draw).
    @MainActor
    static func effect(settings: SettingsStore, named: String = "Pop") {
        guard settings.soundEffects else { return }
        #if os(macOS)
        NSSound(named: named)?.play()
        #else
        AudioServicesPlaySystemSound(1104)
        #endif
    }

    private static func postBanner(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content, trigger: nil)
            center.add(request)
        }
    }
}
