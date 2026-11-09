import Foundation
import ZreadCore

extension Notification.Name {
    static let readerSettingsChanged = Notification.Name("zread.readerSettingsChanged")
}

enum SettingsStore {
    static var current = ReaderSettings.load() {
        didSet {
            guard current != oldValue else { return }
            current.save()
            NotificationCenter.default.post(name: .readerSettingsChanged, object: nil)
        }
    }
}
