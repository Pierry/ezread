import AppKit

final class WelcomeWindowController: NSWindowController {
    private let onOpen: () -> Void

    init(onOpen: @escaping () -> Void) {
        self.onOpen = onOpen
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = Theme.background
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        buildContent(in: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    private func buildContent(in window: NSWindow) {
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 112),
            icon.heightAnchor.constraint(equalToConstant: 112),
        ])

        let title = label("ezread", font: NSFont(name: "Helvetica Neue Bold", size: 34))
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let versionLabel = label("Version \(version)", font: NSFont(name: "Helvetica Neue", size: 13))
        versionLabel.alphaValue = 0.6

        let why = label(
            "Most Markdown gets read inside a code editor, in a side panel with tabs and toolbars all around it. "
                + "ezread was made so your docs can open like an article: just the text, set for reading.",
            font: NSFont(name: "Charter", size: 18)
        )
        let hint = label(
            "Open a folder to browse its docs, or run ezread . from any folder in Terminal.",
            font: NSFont(name: "Charter", size: 15)
        )
        hint.alphaValue = 0.7

        let open = NSButton(title: "Open Folder or File…", target: self, action: #selector(openPressed))
        open.bezelStyle = .rounded
        open.controlSize = .large
        open.keyEquivalent = "\r"

        let stack = NSStackView(views: [icon, title, versionLabel, why, hint, open])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(4, after: title)
        stack.setCustomSpacing(26, after: versionLabel)
        stack.setCustomSpacing(26, after: hint)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = window.contentView!
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor, constant: 8),
            stack.widthAnchor.constraint(equalToConstant: 420),
        ])
    }

    private func label(_ text: String, font: NSFont?) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = font
        field.textColor = Theme.text
        field.alignment = .center
        field.isSelectable = false
        field.preferredMaxLayoutWidth = 420
        return field
    }

    @objc private func openPressed() {
        onOpen()
    }
}
