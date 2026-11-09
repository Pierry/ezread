import AppKit
import ZreadCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controllers: [String: WindowController] = [:]
    private var receivedOpenRequest = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = buildMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.receivedOpenRequest, self.controllers.isEmpty else { return }
            self.openDocument(nil)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        receivedOpenRequest = true
        urls.forEach { open(path: $0.path) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        controllers.values.allSatisfy { $0.confirmDiscardingChanges() } ? .terminateNow : .terminateCancel
    }

    private func open(path: String) {
        do {
            var target = try RootResolver.resolve(path: path)
            if target.wasFile, let file = target.initialFile,
               let enclosing = controllers.keys.first(where: { file.path.hasPrefix($0 + "/") }) {
                target = ResolvedTarget(root: URL(fileURLWithPath: enclosing, isDirectory: true), initialFile: file, wasFile: true)
            }
            let controller = controllers[target.root.path] ?? makeController(for: target)
            controller.present(target: target)
            NSApp.activate(ignoringOtherApps: true)
        } catch RootResolverError.notMarkdown {
            showAlert("zread only opens folders and Markdown files.", path)
        } catch {
            showAlert("Path not found.", path)
        }
    }

    private func makeController(for target: ResolvedTarget) -> WindowController {
        let controller = WindowController(root: target.root)
        controller.onClose = { [weak self] in self?.controllers[target.root.path] = nil }
        controllers[target.root.path] = controller
        return controller
    }

    private func showAlert(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            open(path: url.path)
        }
    }

    @objc func showAbout(_ sender: Any?) {
        let credits = NSAttributedString(
            string: "A Markdown reader for macOS.\nOpen a folder or file with zread . or Cmd+O.",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.labelColor,
            ]
        )
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func installCommand(_ sender: Any?) {
        CLIInstaller.install()
    }

    private func buildMenu() -> NSMenu {
        let main = NSMenu()

        add(to: main, "zread", [
            item("About zread", #selector(showAbout(_:))),
            .separator(),
            item("Settings…", #selector(WindowController.showSettings(_:)), ","),
            item("Install zread Command", #selector(installCommand(_:))),
            .separator(),
            item("Hide zread", #selector(NSApplication.hide(_:)), "h"),
            item("Quit zread", #selector(NSApplication.terminate(_:)), "q"),
        ])
        add(to: main, "File", [
            item("Open Folder or File…", #selector(openDocument(_:)), "o"),
            item("Save", #selector(WindowController.saveDocument(_:)), "s"),
            .separator(),
            item("Close", #selector(NSWindow.performClose(_:)), "w"),
        ])
        add(to: main, "Edit", [
            item("Undo", Selector(("undo:")), "z"),
            item("Redo", Selector(("redo:")), "Z"),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), "x"),
            item("Copy", #selector(NSText.copy(_:)), "c"),
            item("Paste", #selector(NSText.paste(_:)), "v"),
            item("Select All", #selector(NSText.selectAll(_:)), "a"),
        ])
        add(to: main, "View", [
            item("Toggle Reading and Source", #selector(WindowController.toggleSource(_:)), "e"),
            item("Show or Hide Sidebar", #selector(WindowController.toggleSidebar(_:)), "\\"),
            .separator(),
            item("Toggle Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f"),
        ])
        let window = add(to: main, "Window", [
            item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"),
        ])
        NSApp.windowsMenu = window
        return main
    }

    private func item(_ title: String, _ action: Selector, _ key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        if action == #selector(NSWindow.toggleFullScreen(_:)) {
            menuItem.keyEquivalentModifierMask = [.command, .control]
        }
        return menuItem
    }

    @discardableResult
    private func add(to main: NSMenu, _ title: String, _ items: [NSMenuItem]) -> NSMenu {
        let holder = NSMenuItem()
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        holder.submenu = menu
        main.addItem(holder)
        return menu
    }
}
