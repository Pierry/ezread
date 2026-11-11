import Foundation

public struct ReaderSettings: Codable, Equatable {
    public enum FontStyle: String, Codable, CaseIterable {
        case medium
        case charter
        case monospaced
    }

    public enum Appearance: String, Codable, CaseIterable {
        case light
        case dark
        case solarizedLight
        case solarizedDark

        public var isDark: Bool { self == .dark || self == .solarizedDark }
    }

    public static let fontSizeRange = 14.0...32.0
    public static let letterSpacingRange = -0.05...0.15
    public static let lineHeightRange = 1.1...2.4

    private static let defaultsKey = "readerSettings"

    /// nil follows the macOS appearance.
    public var appearance: Appearance?
    public var fontSize: Double = 20
    public var fontStyle: FontStyle = .medium
    /// `#RRGGBB`, or nil to use the theme's text color.
    public var primaryColor: String?
    public var letterSpacing: Double = -0.003
    public var lineHeight: Double = 1.6
    public var bold: Bool = false

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case appearance, fontSize, fontStyle, primaryColor, letterSpacing, lineHeight, bold
    }

    /// Missing or unknown keys fall back to the default, so settings saved by
    /// an older or newer version still load instead of resetting everything.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ReaderSettings()
        appearance = try? container.decodeIfPresent(Appearance.self, forKey: .appearance)
        fontSize = (try? container.decodeIfPresent(Double.self, forKey: .fontSize)) ?? defaults.fontSize
        fontStyle = (try? container.decodeIfPresent(FontStyle.self, forKey: .fontStyle)) ?? defaults.fontStyle
        primaryColor = try? container.decodeIfPresent(String.self, forKey: .primaryColor)
        letterSpacing = (try? container.decodeIfPresent(Double.self, forKey: .letterSpacing)) ?? defaults.letterSpacing
        lineHeight = (try? container.decodeIfPresent(Double.self, forKey: .lineHeight)) ?? defaults.lineHeight
        bold = (try? container.decodeIfPresent(Bool.self, forKey: .bold)) ?? defaults.bold
    }

    /// Returns a copy with every value inside its allowed range. An invalid
    /// color is dropped, because this value is passed to the page.
    public func sanitized() -> ReaderSettings {
        var copy = self
        copy.fontSize = Self.clamp(fontSize, Self.fontSizeRange)
        copy.letterSpacing = Self.clamp(letterSpacing, Self.letterSpacingRange)
        copy.lineHeight = Self.clamp(lineHeight, Self.lineHeightRange)
        if let color = primaryColor, !Self.isValidColor(color) {
            copy.primaryColor = nil
        }
        return copy
    }

    public static func isValidColor(_ value: String) -> Bool {
        value.utf8.count == 7 && value.first == "#" && value.dropFirst().allSatisfy(\.isHexDigit)
    }

    public static func load(from defaults: UserDefaults = .standard) -> ReaderSettings {
        guard let data = defaults.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(ReaderSettings.self, from: data) else {
            return ReaderSettings()
        }
        return settings.sanitized()
    }

    public func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(sanitized()) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }

    public func javaScriptArgument() -> String {
        guard let data = try? JSONEncoder().encode(sanitized()) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
