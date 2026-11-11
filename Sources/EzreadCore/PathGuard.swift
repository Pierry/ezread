import Foundation

public enum PathGuard {
    /// Follows symlinks and `..`. Returns nil if the path does not exist.
    public static func realPath(_ path: String) -> String? {
        guard let resolved = realpath(path, nil) else { return nil }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// Returns the real file for `relativePath`, or nil if it is missing or
    /// resolves to a location outside `root`.
    public static func resolve(relativePath: String, root: URL) -> URL? {
        guard let realRoot = realPath(root.path) else { return nil }
        let combined = (realRoot as NSString).appendingPathComponent(relativePath)
        guard let realTarget = realPath(combined) else { return nil }
        guard realTarget == realRoot || realTarget.hasPrefix(realRoot + "/") else { return nil }
        return URL(fileURLWithPath: realTarget)
    }
}
