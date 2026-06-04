import SwiftUI
import AppKit

/// Manages the desktop companion's floating window (NSPanel): borderless,
/// transparent, always on top, visible on every Space, and draggable by mouse.
/// ProgressStore.partner decides which character is shown.
@MainActor
final class PetController: ObservableObject {
    @Published private(set) var isShowing = false

    private var panel: NSPanel?
    private weak var progress: ProgressStore?
    private weak var engine: TimerEngine?
    private weak var loc: LocalizationManager?

    func toggle(progress: ProgressStore, engine: TimerEngine, loc: LocalizationManager) {
        isShowing ? hide() : show(progress: progress, engine: engine, loc: loc)
    }

    func show(progress: ProgressStore, engine: TimerEngine, loc: LocalizationManager) {
        self.progress = progress
        self.engine = engine
        self.loc = loc
        guard panel == nil else { isShowing = true; return }
        guard let character = progress.partner else { return }

        let view = PetView(character: character, engine: engine, loc: loc) { [weak self] in self?.hide() }
            .environmentObject(progress)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 220)

        let panel = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false

        // Bottom-right of the main screen (clear of the Dock/menu bar).
        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            let origin = NSPoint(x: vf.maxX - 220, y: vf.minY + 20)
            panel.setFrameOrigin(origin)
        }

        panel.orderFrontRegardless()
        self.panel = panel
        isShowing = true
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        isShowing = false
    }

    /// Rebuild the content when the companion character changes, so the sprite updates.
    func refreshIfShowing() {
        guard isShowing, let progress, let engine, let loc else { return }
        hide()
        show(progress: progress, engine: engine, loc: loc)
    }
}
