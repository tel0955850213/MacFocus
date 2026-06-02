import SwiftUI
import AppKit

/// 管理桌面夥伴的浮動視窗(NSPanel)。無邊框、透明、永遠浮在最上層、
/// 可在所有桌面空間顯示,並可用滑鼠拖曳。由 ProgressStore.partner 決定顯示哪隻。
@MainActor
final class PetController: ObservableObject {
    @Published private(set) var isShowing = false

    private var panel: NSPanel?
    private weak var progress: ProgressStore?
    private weak var engine: TimerEngine?

    func toggle(progress: ProgressStore, engine: TimerEngine) {
        isShowing ? hide() : show(progress: progress, engine: engine)
    }

    func show(progress: ProgressStore, engine: TimerEngine) {
        self.progress = progress
        self.engine = engine
        guard panel == nil else { isShowing = true; return }
        guard let character = progress.partner else { return }

        let view = PetView(character: character, engine: engine) { [weak self] in self?.hide() }
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

        // 放到主螢幕右下角(避開 Dock/選單列)。
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

    /// 夥伴角色變更時,重建內容讓 sprite 跟著換。
    func refreshIfShowing() {
        guard isShowing, let progress, let engine else { return }
        hide()
        show(progress: progress, engine: engine)
    }
}
