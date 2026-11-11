import AppKit

enum Theme {
    private struct Palette {
        let background: NSColor
        let text: NSColor
        let selection: NSColor
        let divider: NSColor
    }

    private static func rgb(_ hex: Int) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    private static let light = Palette(
        background: rgb(0xF0EEE9),
        text: rgb(0x242424),
        selection: NSColor.black.withAlphaComponent(0.08),
        divider: NSColor.black.withAlphaComponent(0.08)
    )
    private static let dark = Palette(
        background: rgb(0x0A0A0A),
        text: .white,
        selection: NSColor.white.withAlphaComponent(0.14),
        divider: NSColor.white.withAlphaComponent(0.10)
    )
    private static let solarizedLight = Palette(
        background: rgb(0xFDF6E3),
        text: rgb(0x586E75),
        selection: rgb(0xEEE8D5),
        divider: rgb(0x93A1A1).withAlphaComponent(0.35)
    )
    private static let solarizedDark = Palette(
        background: rgb(0x002B36),
        text: rgb(0x93A1A1),
        selection: rgb(0x073642),
        divider: rgb(0x586E75).withAlphaComponent(0.45)
    )

    /// Resolved at draw time, so it follows both the chosen theme and, for
    /// "System", the macOS appearance.
    private static func dynamic(_ pick: @escaping (Palette) -> NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            switch SettingsStore.current.appearance {
            case .solarizedLight: return pick(solarizedLight)
            case .solarizedDark: return pick(solarizedDark)
            default:
                return pick(appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light)
            }
        }
    }

    static let background = dynamic(\.background)
    static let text = dynamic(\.text)
    static let selection = dynamic(\.selection)
    static let divider = dynamic(\.divider)
}
