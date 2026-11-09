import AppKit
import ZreadCore

extension Notification.Name {
    static let readerSettingsChanged = Notification.Name("zread.readerSettingsChanged")
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
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        case nil: NSApp.appearance = nil
        }
    }
}
