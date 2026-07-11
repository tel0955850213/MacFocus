import AppKit
import Combine
import SwiftUI

/// AppKit-backed status item. We intentionally avoid SwiftUI's MenuBarExtra
/// here: on the current macOS beta it continuously invalidated its label layout
/// and pegged a CPU core. This controller updates only when timer state changes.
@MainActor
final class StatusBarController: NSObject, ObservableObject {
    @Published private(set) var isVisible = false

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var subscriptions = Set<AnyCancellable>()
    private weak var engine: TimerEngine?
    private weak var progress: ProgressStore?
    private weak var loc: LocalizationManager?
    private weak var settings: SettingsStore?

    func attach(engine: TimerEngine, progress: ProgressStore,
                loc: LocalizationManager, settings: SettingsStore) {
        guard self.engine !== engine else { return }
        self.engine = engine
        self.progress = progress
        self.loc = loc
        self.settings = settings

        engine.$remaining
            .combineLatest(engine.$isRunning, engine.$phase)
            .sink { [weak self] _, _, _ in self?.updateButton() }
            .store(in: &subscriptions)
    }

    func setVisible(_ visible: Bool) {
        visible ? show() : hide()
    }

    private func show() {
        guard statusItem == nil else { isVisible = true; updateButton(); return }
        let item = NSStatusBar.system.statusItem(withLength: 78)
        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.imagePosition = .imageLeft
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        button.imageScaling = .scaleProportionallyDown
        statusItem = item
        isVisible = true
        updateButton()
    }

    private func hide() {
        popover.performClose(nil)
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        statusItem = nil
        isVisible = false
    }

    private func updateButton() {
        guard let button = statusItem?.button, let engine else { return }
        button.title = engine.timeString
        button.image = NSImage(systemSymbolName: engine.isRunning ? "timer" : "timer.circle",
                               accessibilityDescription: "Focus timer")
        button.toolTip = engine.phase.titleKey
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button,
              let engine, let progress, let loc, let settings else { return }
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(onOpenApp: { [weak self] in self?.openMainWindow() })
                .environmentObject(engine)
                .environmentObject(progress)
                .environmentObject(loc)
                .environmentObject(settings))
        popover.behavior = .transient
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func openMainWindow() {
        popover.performClose(nil)
        AppLifecycle.setDockIconVisible(true)
        NSApp.activate(ignoringOtherApps: true)
        let mainWindow = NSApp.windows.first { !($0 is NSPanel) && $0 != popover.contentViewController?.view.window }
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}
