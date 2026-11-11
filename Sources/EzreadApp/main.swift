import AppKit

/// The app was called zread before 0.3.0, with its own preferences domain.
/// Carry those settings over once, so the rename does not reset them.
private func migratePreferencesFromZread() {
    let defaults = UserDefaults.standard
    let marker = "migratedFromZread"
    guard !defaults.bool(forKey: marker) else { return }
    if let old = defaults.persistentDomain(forName: "com.pierryborges.zread") {
        for (oldKey, value) in old {
            let key = oldKey.replacingOccurrences(of: "zread.window", with: "ezread.window")
            if defaults.object(forKey: key) == nil { defaults.set(value, forKey: key) }
        }
    }
    defaults.set(true, forKey: marker)
}

migratePreferencesFromZread()

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.run()
