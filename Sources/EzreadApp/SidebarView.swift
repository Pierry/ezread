import AppKit

/// Collapsible side menu: the folder tree, or the settings, with a gear at the
/// bottom to switch between them.
final class SidebarView: NSView {
    private static let footerHeight: CGFloat = 40

    let tree = FileTreeView()
    private let settings = SettingsPanel()
    private let gear = NSButton()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true

        settings.isHidden = true
        addSubview(tree)
        addSubview(settings)

        gear.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
        gear.title = "Settings"
        gear.imagePosition = .imageLeading
        gear.isBordered = false
        gear.font = NSFont(name: "Helvetica Neue", size: 13)
        gear.contentTintColor = Theme.text
        gear.target = self
        gear.action = #selector(toggleSettings)
        gear.toolTip = "Reading settings (Cmd+,)"
        addSubview(gear)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = Theme.background.cgColor
    }

    override func layout() {
        super.layout()
        let content = NSRect(x: 0, y: Self.footerHeight, width: bounds.width, height: max(0, bounds.height - Self.footerHeight))
        tree.frame = content
        settings.frame = content
        gear.frame = NSRect(x: 16, y: 8, width: 100, height: 24)
    }

    func showSettings() {
        setSettings(visible: true)
    }

    @objc private func toggleSettings() {
        setSettings(visible: settings.isHidden)
    }

    private func setSettings(visible: Bool) {
        settings.isHidden = !visible
        tree.isHidden = visible
        gear.title = visible ? "Files" : "Settings"
        gear.image = NSImage(
            systemSymbolName: visible ? "folder" : "gearshape",
            accessibilityDescription: gear.title
        )
    }
}
