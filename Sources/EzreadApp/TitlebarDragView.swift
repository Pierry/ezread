import AppKit

/// Content reaches under the transparent title bar, so the web view would take
/// its clicks. This strip restores dragging and the double-click action.
final class TitlebarDragView: NSView {
    static let height: CGFloat = 40

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        guard event.clickCount == 2 else {
            window.performDrag(with: event)
            return
        }
        switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
        case "None":
            break
        case "Minimize":
            window.performMiniaturize(nil)
        default:
            window.performZoom(nil)
        }
    }
}
