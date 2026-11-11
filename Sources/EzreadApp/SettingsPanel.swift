import AppKit
import EzreadCore

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
    private let bold = NSButton(checkboxWithTitle: "Bold", target: nil, action: nil)
    private let swatches = ColorSwatches()

    /// Called when a color is picked for the open document. nil is the default.
    var onPickColor: ((String?) -> Void)? {
        get { swatches.onPick }
        set { swatches.onPick = newValue }
    }

    private static let themes: [(String, ReaderSettings.Appearance?)] = [
        ("System", nil),
        ("Light", .light),
        ("Dark", .dark),
        ("Solarized Light", .solarizedLight),
        ("Solarized Dark", .solarizedDark),
    ]
    private static let fonts: [(String, ReaderSettings.FontStyle)] = [
        ("Source Serif", .medium),
        ("Charter", .charter),
        ("Monospaced", .monospaced),
    ]

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

        theme.addItems(withTitles: Self.themes.map(\.0))
        theme.target = self
        theme.action = #selector(controlChanged)

        fontStyle.addItems(withTitles: Self.fonts.map(\.0))
        fontStyle.target = self
        fontStyle.action = #selector(controlChanged)

        bold.target = self
        bold.action = #selector(controlChanged)
        bold.font = NSFont(name: "Helvetica Neue", size: 13)
        let fontRow = NSStackView(views: [fontStyle, bold])
        fontRow.spacing = 12

        configure(fontSize, ReaderSettings.fontSizeRange)
        configure(letterSpacing, ReaderSettings.letterSpacingRange)
        configure(lineHeight, ReaderSettings.lineHeightRange)

        swatches.isEnabled = false

        let reset = NSButton(title: "Restore Defaults", target: self, action: #selector(resetAll))
        reset.controlSize = .small

        addHeader("Theme", nil)
        stack.addArrangedSubview(theme)
        stack.setCustomSpacing(16, after: theme)
        addHeader("Font", nil)
        stack.addArrangedSubview(fontRow)
        addSlider("Size", fontSizeValue, fontSize)
        addSlider("Letter spacing", letterSpacingValue, letterSpacing)
        addSlider("Line height", lineHeightValue, lineHeight)
        addHeader("Color for this document", nil)
        stack.addArrangedSubview(swatches)
        stack.setCustomSpacing(20, after: swatches)
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
        theme.selectItem(at: Self.themes.firstIndex { $0.1 == settings.appearance } ?? 0)
        fontStyle.selectItem(at: Self.fonts.firstIndex { $0.1 == settings.fontStyle } ?? 0)
        bold.state = settings.bold ? .on : .off
        fontSize.doubleValue = settings.fontSize
        fontSizeValue.stringValue = String(format: "%.0f px", settings.fontSize)
        letterSpacing.doubleValue = settings.letterSpacing
        letterSpacingValue.stringValue = String(format: "%.3f em", settings.letterSpacing)
        lineHeight.doubleValue = settings.lineHeight
        lineHeightValue.stringValue = String(format: "%.2f", settings.lineHeight)
        swatches.needsDisplay = true
    }

    @objc private func controlChanged(_ sender: Any?) {
        var settings = SettingsStore.current
        settings.appearance = Self.themes[max(0, theme.indexOfSelectedItem)].1
        settings.fontStyle = Self.fonts[max(0, fontStyle.indexOfSelectedItem)].1
        settings.bold = bold.state == .on
        settings.fontSize = fontSize.doubleValue.rounded()
        settings.letterSpacing = (letterSpacing.doubleValue * 1000).rounded() / 1000
        settings.lineHeight = (lineHeight.doubleValue * 100).rounded() / 100
        SettingsStore.current = settings
    }

    @objc private func resetAll() {
        SettingsStore.current = ReaderSettings()
    }

    /// Shows the open document's color. Disabled when no document is open.
    func show(documentColor: String?, enabled: Bool) {
        swatches.selected = documentColor
        swatches.isEnabled = enabled
    }
}
