import Darwin
import Foundation

/// The primary color chosen for one document, kept as an extended attribute on
/// the file itself. The Markdown text never changes, and the color follows the
/// file when it is moved or renamed.
public enum DocumentColor {
    static let attribute = "com.pierryborges.ezread.primaryColor"

    /// The saved `#RRGGBB`, or nil when none was chosen or the value is invalid.
    public static func read(from url: URL) -> String? {
        let size = getxattr(url.path, attribute, nil, 0, 0, 0)
        guard size > 0, size <= 16 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard getxattr(url.path, attribute, &buffer, size, 0, 0) == size else { return nil }
        let value = String(decoding: buffer, as: UTF8.self)
        return ReaderSettings.isValidColor(value) ? value.uppercased() : nil
    }

    /// Saves the color, or removes it when `color` is nil. Invalid values are
    /// treated as nil.
    @discardableResult
    public static func write(_ color: String?, to url: URL) -> Bool {
        guard let color, ReaderSettings.isValidColor(color) else {
            let result = removexattr(url.path, attribute, 0)
            return result == 0 || errno == ENOATTR
        }
        let bytes = Array(color.uppercased().utf8)
        return setxattr(url.path, attribute, bytes, bytes.count, 0, 0) == 0
    }
}
