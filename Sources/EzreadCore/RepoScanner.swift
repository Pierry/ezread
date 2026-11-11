import Foundation

public struct FileNode: Equatable {
    public let name: String
    public let relativePath: String
    public let children: [FileNode]?

    public var isDirectory: Bool { children != nil }

    public init(name: String, relativePath: String, children: [FileNode]?) {
        self.name = name
        self.relativePath = relativePath
        self.children = children
    }
}

public enum RepoScanner {
    private static let alwaysHidden: Set<String> = [".git", "node_modules"]

    public static func scan(root: URL) async -> [FileNode] {
        await Task.detached(priority: .userInitiated) { scanSync(root: root) }.value
    }

    public static func scanSync(root: URL) -> [FileNode] {
        let paths = gitPaths(root: root) ?? walkPaths(root: root)
        let visible = paths.filter { path in
            isMarkdown(path) && !path.split(separator: "/").contains { alwaysHidden.contains(String($0)) }
        }
        return buildTree(paths: visible)
    }

    public static func isMarkdown(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return ext == "md" || ext == "markdown"
    }

    private static func gitPaths(root: URL) -> [String]? {
        guard FileManager.default.fileExists(atPath: root.appendingPathComponent(".git").path) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = root
        process.arguments = ["ls-files", "-co", "--exclude-standard", "-z", "--", ":(icase)*.md", ":(icase)*.markdown"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        return String(decoding: data, as: UTF8.self)
            .split(separator: "\0")
            .map(String.init)
            .filter { FileManager.default.fileExists(atPath: root.appendingPathComponent($0).path) }
    }

    private static func walkPaths(root: URL) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return [] }

        let prefix = root.standardizedFileURL.path + "/"
        var paths: [String] = []
        for case let url as URL in enumerator {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                if alwaysHidden.contains(url.lastPathComponent) { enumerator.skipDescendants() }
                continue
            }
            let path = url.standardizedFileURL.path
            if path.hasPrefix(prefix) { paths.append(String(path.dropFirst(prefix.count))) }
        }
        return paths
    }

    private final class Builder {
        var directories: [String: Builder] = [:]
        var files: [String] = []
    }

    static func buildTree(paths: [String]) -> [FileNode] {
        let top = Builder()
        for path in paths {
            var current = top
            let parts = path.split(separator: "/").map(String.init)
            guard let fileName = parts.last else { continue }
            for part in parts.dropLast() {
                let next = current.directories[part] ?? Builder()
                current.directories[part] = next
                current = next
            }
            current.files.append(fileName)
        }
        return nodes(from: top, prefix: "")
    }

    private static func nodes(from builder: Builder, prefix: String) -> [FileNode] {
        let directories = builder.directories.keys
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { name -> FileNode in
                let path = prefix + name
                return FileNode(name: name, relativePath: path, children: nodes(from: builder.directories[name]!, prefix: path + "/"))
            }
        let files = builder.files
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { FileNode(name: $0, relativePath: prefix + $0, children: nil) }
        return directories + files
    }
}
