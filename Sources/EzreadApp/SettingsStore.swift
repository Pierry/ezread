import AppKit
import EzreadCore

extension Notification.Name {
    static let readerSettingsChanged = Notification.Name("ezread.readerSettingsChanged")
}

enum SettingsStore {
    static var current = ReaderSettings.load() {
        didSet {
            guard current != oldValue else { return }
            current.save()
            applyAppearance()
            NotificationCenter.default.post(name: .readerSettingsChanged, object: nil)
        }
    }

    static func applyAppearance() {
        switch current.appearance {
        case nil: NSApp.appearance = nil
        case let appearance?:
            NSApp.appearance = NSAppearance(named: appearance.isDark ? .darkAqua : .aqua)
        }
        // Light and Solarized Light share the same macOS appearance, so AppKit
        // would not redraw on that switch by itself.
        for window in NSApp.windows {
            window.backgroundColor = Theme.background
            if let view = window.contentView { redraw(view) }
        }
    }

    private static func redraw(_ view: NSView) {
        view.needsDisplay = true
        view.subviews.forEach(redraw)
    }
}
