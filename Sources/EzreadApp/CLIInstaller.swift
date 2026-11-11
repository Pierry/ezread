import AppKit

enum CLIInstaller {
    private static let linkPath = "/usr/local/bin/ezread"

    static func install() {
        let binary = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/ezread").path
        let manager = FileManager.default

        do {
            if let existing = try? manager.destinationOfSymbolicLink(atPath: linkPath) {
                if existing == binary {
                    show("The ezread command is already installed.", linkPath)
                    return
                }
                try manager.removeItem(atPath: linkPath)
            } else if manager.fileExists(atPath: linkPath) {
                show("A file already exists at \(linkPath).", "Remove it and try again.")
                return
            }
            try manager.createSymbolicLink(atPath: linkPath, withDestinationPath: binary)
            show("ezread command installed.", linkPath)
        } catch {
            show("No permission to install. Run this in Terminal:", "sudo ln -sf \"\(binary)\" \(linkPath)")
        }
    }

    private static func show(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}
