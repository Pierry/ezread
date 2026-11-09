import AppKit
import ZreadCore

final class WindowController: NSWindowController, NSWindowDelegate, NSMenuItemValidation {
    private static let highlightLimit = 2 * 1024 * 1024
    private static let sidebarWidth: CGFloat = 260

    private let root: URL
    private let split = NSSplitView()
    private let sidebar = SidebarView()
    private var tree: FileTreeView { sidebar.tree }
    private let content = NSView()
    private let reader: ReaderView
    private let source = SourceEditor()

    private let editButton = NSButton()
    private let saveButton = NSButton()

    private var session: DocumentSession?
    private var isShowingSource = false
    private var renderedText: String?
    private var lastNodes: [FileNode]?
    private var sidebarDecided = false
    private var measured = false

    var onClose: (() -> Void)?

    init(root: URL) {
        self.root = root
        SettingsStore.applyAppearance()
        self.reader = ReaderView(root: root)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = Theme.background
        window.minSize = NSSize(width: 480, height: 560)
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
        buildLayout(in: window)
        connectCallbacks()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    private func buildLayout(in window: NSWindow) {
        split.isVertical = true
        split.dividerStyle = .thin
        split.autoresizingMask = [.width, .height]
        split.frame = window.contentView!.bounds
        window.contentView!.addSubview(split)

        sidebar.frame = NSRect(x: 0, y: 0, width: Self.sidebarWidth, height: split.bounds.height)
        split.addSubview(sidebar)
        split.addSubview(content)
        split.setHoldingPriority(.defaultHigh, forSubviewAt: 0)
        sidebar.isHidden = true
        addSidebarButton(to: window)
        addEditButtons(to: window)

        for view in [reader, source] as [NSView] {
            view.frame = content.bounds
            view.autoresizingMask = [.width, .height]
            content.addSubview(view)
        }
        source.isHidden = true

        let bounds = window.contentView!.bounds
        let dragStrip = TitlebarDragView(frame: NSRect(
            x: 0,
            y: bounds.height - TitlebarDragView.height,
            width: bounds.width,
            height: TitlebarDragView.height
        ))
        dragStrip.autoresizingMask = [.width, .minYMargin]
        window.contentView!.addSubview(dragStrip)
    }

    /// Sits beside the window buttons, so it stays visible when collapsed.
    private func addSidebarButton(to window: NSWindow) {
        let image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Show or hide sidebar")!
        let button = NSButton(image: image, target: self, action: #selector(toggleSidebar(_:)))
        button.isBordered = false
        button.contentTintColor = Theme.text
        button.toolTip = "Show or hide sidebar (Cmd+\\)"
        button.frame = NSRect(x: 8, y: 2, width: 28, height: 24)

        let holder = NSView(frame: NSRect(x: 0, y: 0, width: 44, height: 28))
        holder.addSubview(button)

        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = holder
        accessory.layoutAttribute = .leading
        window.addTitlebarAccessoryViewController(accessory)
    }

    private func addEditButtons(to window: NSWindow) {
        saveButton.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Save")
        saveButton.toolTip = "Save (Cmd+S)"
        saveButton.target = self
        saveButton.action = #selector(saveDocument(_:))
        saveButton.frame = NSRect(x: 4, y: 2, width: 28, height: 24)

        editButton.target = self
        editButton.action = #selector(toggleSource(_:))
        editButton.frame = NSRect(x: 40, y: 2, width: 28, height: 24)

        let holder = NSView(frame: NSRect(x: 0, y: 0, width: 80, height: 28))
        for button in [saveButton, editButton] {
            button.isBordered = false
            button.contentTintColor = Theme.text
            holder.addSubview(button)
        }

        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = holder
        accessory.layoutAttribute = .trailing
        window.addTitlebarAccessoryViewController(accessory)
        refreshEditControls()
    }

    private func refreshEditControls() {
        let isDirty = session?.isDirty ?? false
        window?.isDocumentEdited = isDirty
        saveButton.isHidden = !isDirty
        editButton.isEnabled = session != nil
        let label = isShowingSource ? "Read" : "Edit"
        editButton.image = NSImage(
            systemSymbolName: isShowingSource ? "book" : "pencil",
            accessibilityDescription: label
        )
        editButton.toolTip = "\(label) (Cmd+E)"
    }

    private func connectCallbacks() {
        tree.onSelect = { [weak self] path in self?.open(relativePath: path, fragment: nil) }
        reader.onInternalLink = { [weak self] path, fragment in self?.open(relativePath: path, fragment: fragment) }
        source.onChange = { [weak self] in
            guard let self, let session = self.session else { return }
            session.text = self.source.string
            self.refreshEditControls()
        }
    }

    // MARK: Opening

    func present(target: ResolvedTarget) {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)

        if let file = target.initialFile {
            open(file: file, fragment: nil)
        } else if session == nil {
            reader.show(html: "<p class=\"empty\">Choose a file from the list.</p>", highlight: false)
        }
        refreshTree(showSidebarIfUseful: !target.wasFile, forceSidebar: target.initialFile == nil)
    }

    private func open(relativePath: String, fragment: String?) {
        guard let file = PathGuard.resolve(relativePath: relativePath, root: root) else {
            NSSound.beep()
            return
        }
        open(file: file, fragment: fragment)
    }

    private func open(file: URL, fragment: String?) {
        if session?.url.path == file.path {
            if let fragment { reader.scrollTo(anchor: fragment) }
            return
        }
        guard confirmDiscardingChanges() else {
            tree.select(relativePath: currentRelativePath)
            return
        }

        let next = DocumentSession(url: file)
        do {
            try next.load()
        } catch {
            showError("Could not read this file as UTF-8.", file.path)
            tree.select(relativePath: currentRelativePath)
            return
        }

        session = next
        renderedText = nil
        window?.title = file.lastPathComponent
        window?.representedURL = file
        showReaderPane()
        render {
            if let fragment { self.reader.scrollTo(anchor: fragment) }
        }
        tree.select(relativePath: currentRelativePath)
    }

    private var currentRelativePath: String? {
        guard let path = session?.url.path, path.hasPrefix(root.path + "/") else { return nil }
        return String(path.dropFirst(root.path.count + 1))
    }

    private func render(completion: (() -> Void)? = nil) {
        guard let session else { return }
        let directory = (currentRelativePath.map { ($0 as NSString).deletingLastPathComponent }) ?? ""
        let rendered = MarkdownRenderer.render(markdown: session.text, documentDirectory: directory)
        let highlight = rendered.hasCode && session.text.utf8.count <= Self.highlightLimit
        renderedText = session.text
        reader.show(html: rendered.html, highlight: highlight) { [weak self] in
            completion?()
            self?.recordMeasurement()
        }
    }

    private func refreshTree(showSidebarIfUseful: Bool = false, forceSidebar: Bool = false) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let nodes = await RepoScanner.scan(root: self.root)
            if nodes != self.lastNodes {
                self.lastNodes = nodes
                self.tree.update(nodes: nodes, selected: self.currentRelativePath)
            }
            if !self.sidebarDecided {
                self.sidebarDecided = true
                let hasSeveral = nodes.count > 1 || nodes.first?.isDirectory == true
                if forceSidebar || (showSidebarIfUseful && hasSeveral) {
                    self.setSidebar(visible: true)
                }
            }
        }
    }

    // MARK: Modes

    private func showReaderPane() {
        isShowingSource = false
        source.isHidden = true
        reader.isHidden = false
        window?.makeFirstResponder(reader.web)
        refreshEditControls()
    }

    private func showSourcePane() {
        isShowingSource = true
        reader.isHidden = true
        source.isHidden = false
        window?.makeFirstResponder(source.editorView)
        refreshEditControls()
    }

    @objc func toggleSource(_ sender: Any?) {
        guard let session else { return }

        if isShowingSource {
            let line = source.topVisibleLine()
            session.text = source.string
            showReaderPane()
            if renderedText != session.text {
                render { self.reader.scrollTo(line: line) }
            } else {
                reader.scrollTo(line: line)
            }
        } else {
            reader.topVisibleLine { [weak self] line in
                guard let self, let session = self.session else { return }
                self.source.string = session.text
                self.showSourcePane()
                self.source.layoutSubtreeIfNeeded()
                self.source.scrollTo(line: line)
            }
        }
    }

    @objc func toggleSidebar(_ sender: Any?) {
        setSidebar(visible: sidebar.isHidden)
    }

    @objc func showSettings(_ sender: Any?) {
        setSidebar(visible: true)
        sidebar.showSettings()
    }

    private func setSidebar(visible: Bool) {
        sidebar.isHidden = !visible
        if visible {
            split.setPosition(Self.sidebarWidth, ofDividerAt: 0)
        }
        split.adjustSubviews()
    }

    // MARK: Saving

    @objc func saveDocument(_ sender: Any?) {
        _ = saveCurrent()
    }

    private func saveCurrent() -> Bool {
        guard let session else { return true }
        if isShowingSource { session.text = source.string }

        do {
            switch try session.save() {
            case .saved:
                refreshEditControls()
                return true
            case .conflict:
                let alert = NSAlert()
                alert.messageText = "This file changed on disk."
                alert.informativeText = "Saving now replaces the version on disk."
                alert.addButton(withTitle: "Overwrite")
                alert.addButton(withTitle: "Cancel")
                guard alert.runModal() == .alertFirstButtonReturn else { return false }
                _ = try session.save(force: true)
                refreshEditControls()
                return true
            }
        } catch {
            showError("Could not save.", error.localizedDescription)
            return false
        }
    }

    func confirmDiscardingChanges() -> Bool {
        guard let session else { return true }
        if isShowingSource { session.text = source.string }
        guard session.isDirty else { return true }

        let alert = NSAlert()
        alert.messageText = "Save changes to \(session.url.lastPathComponent)?"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn: return saveCurrent()
        case .alertSecondButtonReturn: return true
        default: return false
        }
    }

    // MARK: Window events

    func windowDidBecomeKey(_ notification: Notification) {
        reloadIfChangedOnDisk()
        if lastNodes != nil { refreshTree() }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        confirmDiscardingChanges()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(saveDocument(_:)):
            if isShowingSource, let session { session.text = source.string }
            return session?.isDirty ?? false
        case #selector(toggleSource(_:)):
            return session != nil
        default:
            return true
        }
    }

    private func reloadIfChangedOnDisk() {
        guard let session, !session.isDirty, session.changedOnDisk() else { return }
        guard (try? session.load()) != nil else { return }

        if isShowingSource {
            let line = source.topVisibleLine()
            source.string = session.text
            source.scrollTo(line: line)
            renderedText = nil
        } else {
            reader.topVisibleLine { [weak self] line in
                self?.render { self?.reader.scrollTo(line: line) }
            }
        }
    }

    private func showError(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }

    /// Used only by scripts/measure.sh.
    private func recordMeasurement() {
        guard !measured else { return }
        measured = true
        let environment = ProcessInfo.processInfo.environment
        guard let output = environment["ZREAD_MEASURE_OUT"],
              let start = environment["ZREAD_MEASURE_START"].flatMap(Double.init) else { return }
        let milliseconds = Int((Date().timeIntervalSince1970 - start) * 1000)
        try? "\(milliseconds)\n".write(toFile: output, atomically: true, encoding: .utf8)
    }
}
