import AppKit

/// A row of round color swatches. The first is the default (black, or the
/// theme's text color), and the last opens the macOS color wheel for any color.
final class ColorSwatches: NSView {
    static let presets = ["#2F6FD0", "#1A8917", "#D93025", "#E8710A", "#8E44D6"]

    private static let diameter: CGFloat = 22
    private static let gap: CGFloat = 10
    private static var count: Int { presets.count + 2 }

    /// Called with `#RRGGBB`, or nil for the default.
    var onPick: ((String?) -> Void)?

    var selected: String? {
        didSet { needsDisplay = true }
    }

    var isEnabled = true {
        didSet {
            alphaValue = isEnabled ? 1 : 0.35
            window?.invalidateCursorRects(for: self)
        }
    }

    override var intrinsicContentSize: NSSize {
        let count = CGFloat(Self.count)
        return NSSize(width: count * Self.diameter + (count - 1) * Self.gap + 4, height: Self.diameter + 4)
    }

    override var isFlipped: Bool { true }

    private func frame(at index: Int) -> NSRect {
        NSRect(x: 2 + CGFloat(index) * (Self.diameter + Self.gap), y: 2, width: Self.diameter, height: Self.diameter)
    }

    private var customIndex: Int { Self.presets.count + 1 }

    private var selectedIndex: Int {
        guard let selected else { return 0 }
        if let preset = Self.presets.firstIndex(of: selected) { return preset + 1 }
        return customIndex
    }

    override func draw(_ dirtyRect: NSRect) {
        for index in 0..<Self.count {
            let rect = frame(at: index)
            let circle = NSBezierPath(ovalIn: rect)

            if index == 0 {
                NSColor.black.setFill()
                circle.fill()
            } else if index == customIndex {
                if selectedIndex == customIndex, let color = selected.flatMap(Self.color(fromHex:)) {
                    color.setFill()
                    circle.fill()
                } else {
                    drawWheel(in: rect)
                }
            } else {
                Self.color(fromHex: Self.presets[index - 1])?.setFill()
                circle.fill()
            }

            // A thin edge keeps black visible on dark themes.
            Theme.text.withAlphaComponent(0.25).setStroke()
            circle.lineWidth = 1
            circle.stroke()

            if index == selectedIndex {
                let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 4, dy: 4))
                NSColor.white.setStroke()
                ring.lineWidth = 2
                ring.stroke()
            }
        }
    }

    private func drawWheel(in rect: NSRect) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        let steps = 36
        for step in 0..<steps {
            let start = CGFloat(step) / CGFloat(steps) * 360
            let wedge = NSBezierPath()
            wedge.move(to: center)
            wedge.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: start + 360 / CGFloat(steps) + 0.5)
            wedge.close()
            NSColor(hue: CGFloat(step) / CGFloat(steps), saturation: 0.85, brightness: 0.95, alpha: 1).setFill()
            wedge.fill()
        }
    }

    override func resetCursorRects() {
        guard isEnabled else { return }
        for index in 0..<Self.count {
            addCursorRect(frame(at: index), cursor: .pointingHand)
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        let point = convert(event.locationInWindow, from: nil)
        guard let index = (0..<Self.count).first(where: { frame(at: $0).insetBy(dx: -3, dy: -3).contains(point) }) else { return }

        switch index {
        case 0: pick(nil)
        case customIndex: openWheel()
        default: pick(Self.presets[index - 1])
        }
    }

    private func pick(_ color: String?) {
        selected = color
        onPick?(color)
    }

    private func openWheel() {
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.mode = .wheel
        panel.isContinuous = true
        panel.setTarget(nil)
        panel.setAction(nil)
        panel.color = selected.flatMap(Self.color(fromHex:)) ?? .black
        panel.setTarget(self)
        panel.setAction(#selector(wheelChanged(_:)))
        panel.orderFront(nil)
    }

    @objc private func wheelChanged(_ sender: NSColorPanel) {
        guard isEnabled, let hex = Self.hex(from: sender.color) else { return }
        pick(hex)
    }

    static func hex(from color: NSColor) -> String? {
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        let value = { (component: CGFloat) in Int((min(max(component, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", value(rgb.redComponent), value(rgb.greenComponent), value(rgb.blueComponent))
    }

    static func color(fromHex hex: String) -> NSColor? {
        guard hex.count == 7, let value = Int(hex.dropFirst(), radix: 16) else { return nil }
        return NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
