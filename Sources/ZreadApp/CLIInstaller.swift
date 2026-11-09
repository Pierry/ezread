import AppKit

enum CLIInstaller {
    private static let linkPath = "/usr/local/bin/zread"

    static func install() {
        let binary = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/zread").path
        let manager = FileManager.default

        do {
            if let existing = try? manager.destinationOfSymbolicLink(atPath: linkPath) {
                if existing == binary {
                    show("O comando zread já está instalado.", linkPath)
                    return
                }
                try manager.removeItem(atPath: linkPath)
            } else if manager.fileExists(atPath: linkPath) {
                show("Já existe um arquivo em \(linkPath).", "Remova-o e tente de novo.")
                return
            }
            try manager.createSymbolicLink(atPath: linkPath, withDestinationPath: binary)
            show("Comando zread instalado.", linkPath)
        } catch {
            show("Sem permissão para instalar. Rode no terminal:", "sudo ln -sf \"\(binary)\" \(linkPath)")
        }
    }

    private static func show(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}
