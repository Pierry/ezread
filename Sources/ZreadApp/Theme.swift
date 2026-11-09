import AppKit

enum Theme {
    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    static let background = dynamic(
        light: NSColor(srgbRed: 0xF0 / 255, green: 0xEE / 255, blue: 0xE9 / 255, alpha: 1),
        dark: NSColor(srgbRed: 0x0A / 255, green: 0x0A / 255, blue: 0x0A / 255, alpha: 1)
    )
    static let text = dynamic(
        light: NSColor(srgbRed: 0x24 / 255, green: 0x24 / 255, blue: 0x24 / 255, alpha: 1),
        dark: .white
    )
    static let selection = dynamic(
        light: NSColor.black.withAlphaComponent(0.08),
        dark: NSColor.white.withAlphaComponent(0.14)
    )
    static let divider = dynamic(
        light: NSColor.black.withAlphaComponent(0.08),
        dark: NSColor.white.withAlphaComponent(0.10)
    )
}
