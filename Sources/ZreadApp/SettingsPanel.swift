import AppKit
import ZreadCore

/// Reader typography controls, shown inside the sidebar.
final class SettingsPanel: NSView {
    private let stack = NSStackView()
    private let theme = NSPopUpButton()
    private let fontStyle = NSPopUpButton()
    private let fontSize = NSSlider()
    private let fontSizeValue = SettingsPanel.valueLabel()
    private let letterSpacing = NSSlider()
    private let letterSpacingValue = SettingsPanel.valueLabel()
    private let lineHeight = NSSlider()
    private let lineHeightValue = SettingsPanel.valueLabel()
    private let color = NSColorWell(style: .minimal)

    override init(frame: NSRect) {
        super.init(frame: frame)

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 48, left: 16, bottom: 12, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        theme.addItems(withTitles: ["System", "Light", "Dark"])
        theme.target = self
        theme.action = #selector(controlChanged)

        fontStyle.addItems(withTitles: ["Serif", "Monospaced"])
        fontStyle.target = self
        fontStyle.action = #selector(controlChanged)

        configure(fontSize, ReaderSettings.fontSizeRange)
        configure(letterSpacing, ReaderSettings.letterSpacingRange)
        configure(lineHeight, ReaderSettings.lineHeightRange)

        color.target = self
        color.action = #selector(controlChanged)
        let useDefaultColor = NSButton(title: "Default", target: self, action: #selector(resetColor))
        useDefaultColor.controlSize = .small
        let colorRow = NSStackView(views: [color, useDefaultColor])
        colorRow.spacing = 10

        let reset = NSButton(title: "Restore Defaults", target: self, action: #selector(resetAll))
        reset.controlSize = .small

        addHeader("Theme", nil)
        stack.addArrangedSubview(theme)
        stack.setCustomSpacing(16, after: theme)
        addHeader("Font", nil)
        stack.addArrangedSubview(fontStyle)
        addSlider("Size", fontSizeValue, fontSize)
        addSlider("Letter spacing", letterSpacingValue, letterSpacing)
        addSlider("Line height", lineHeightValue, lineHeight)
        addHeader("Primary color", nil)
        stack.addArrangedSubview(colorRow)
        stack.setCustomSpacing(20, after: colorRow)
        stack.addArrangedSubview(reset)

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .readerSettingsChanged, object: nil)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private static func valueLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont(name: "Helvetica Neue", size: 12)
        label.textColor = Theme.text
        label.alphaValue = 0.6
        label.alignment = .right
        return label
    }

    private func configure(_ slider: NSSlider, _ range: ClosedRange<Double>) {
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.isContinuous = true
        slider.controlSize = .small
        slider.target = self
        slider.action = #selector(controlChanged)
    }

    private func addHeader(_ title: String, _ value: NSTextField?) {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont(name: "Helvetica Neue", size: 13)
        label.textColor = Theme.text

        guard let value else {
            stack.addArrangedSubview(label)
            return
        }
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let row = NSStackView(views: [label, spacer, value])
        row.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
    }

    private func addSlider(_ title: String, _ value: NSTextField, _ slider: NSSlider) {
        stack.setCustomSpacing(16, after: stack.arrangedSubviews.last!)
        addHeader(title, value)
        slider.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(slider)
        slider.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        stack.setCustomSpacing(16, after: slider)
    }

    @objc private func refresh() {
        let settings = SettingsStore.current
        theme.selectItem(at: settings.appearance == nil ? 0 : (settings.appearance == .light ? 1 : 2))
        fontStyle.selectItem(at: settings.fontStyle == .medium ? 0 : 1)
        fontSize.doubleValue = settings.fontSize
        fontSizeValue.stringValue = String(format: "%.0f px", settings.fontSize)
        letterSpacing.doubleValue = settings.letterSpacing
        letterSpacingValue.stringValue = String(format: "%.3f em", settings.letterSpacing)
        lineHeight.doubleValue = settings.lineHeight
        lineHeightValue.stringValue = String(format: "%.2f", settings.lineHeight)
        color.color = settings.primaryColor.flatMap(Self.color(fromHex:)) ?? Theme.text
    }

    @objc private func controlChanged(_ sender: Any?) {
        var settings = SettingsStore.current
        settings.appearance = [nil, .light, .dark][theme.indexOfSelectedItem]
        settings.fontStyle = fontStyle.indexOfSelectedItem == 0 ? .medium : .monospaced
        settings.fontSize = fontSize.doubleValue.rounded()
        settings.letterSpacing = (letterSpacing.doubleValue * 1000).rounded() / 1000
        settings.lineHeight = (lineHeight.doubleValue * 100).rounded() / 100
        if sender as? NSColorWell === color {
            settings.primaryColor = Self.hex(from: color.color)
        }
        SettingsStore.current = settings
    }

    @objc private func resetColor() {
        SettingsStore.current.primaryColor = nil
    }

    @objc private func resetAll() {
        SettingsStore.current = ReaderSettings()
    }

    private static func hex(from color: NSColor) -> String? {
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        let value = { (component: CGFloat) in Int((component * 255).rounded()) }
        return String(format: "#%02X%02X%02X", value(rgb.redComponent), value(rgb.greenComponent), value(rgb.blueComponent))
    }

    private static func color(fromHex hex: String) -> NSColor? {
        guard let value = Int(hex.dropFirst(), radix: 16) else { return nil }
        return NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
