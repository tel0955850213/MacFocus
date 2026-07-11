import AppKit
import ServiceManagement

/// Runtime app-presence controls for the menu-bar timer feature: hiding the
/// Dock icon and registering for launch-at-login. Both are toggleable from
/// Settings without relaunching the app.
enum AppLifecycle {

    /// Show/hide the Dock icon. Done at runtime via `setActivationPolicy`
    /// rather than the Info.plist `LSUIElement` key, which would make it
    /// permanent and unreachable from an in-app toggle.
    @MainActor
    static func setDockIconVisible(_ visible: Bool) {
        NSApp.setActivationPolicy(visible ? .regular : .accessory)
        if visible {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Register/unregister launch-at-login via ServiceManagement. No
    /// entitlement needed; requires a stable code-signing identity (already
    /// set via `DEVELOPMENT_TEAM` in project.yml).
    static func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // Non-fatal: surfacing this as a hard error would be disruptive for a
            // background convenience setting. Log for diagnosis.
            print("AppLifecycle.setLaunchAtLogin(\(enabled)) failed: \(error)")
        }
    }

    /// True if the user needs to approve this app in System Settings ▸ Login
    /// Items before launch-at-login actually takes effect.
    static var launchAtLoginNeedsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }
}
