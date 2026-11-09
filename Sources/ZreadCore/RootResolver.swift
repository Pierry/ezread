import Foundation

public struct ResolvedTarget: Equatable {
    public let root: URL
    public let initialFile: URL?
    public let wasFile: Bool

    public init(root: URL, initialFile: URL?, wasFile: Bool) {
        self.root = root
        self.initialFile = initialFile
        self.wasFile = wasFile
    }
}

public enum RootResolverError: Error, Equatable {
    case notFound
    case notMarkdown
}

public enum RootResolver {
    public static func resolve(path: String) throws -> ResolvedTarget {
        guard let real = PathGuard.realPath(path) else { throw RootResolverError.notFound }

        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: real, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            let root = URL(fileURLWithPath: real, isDirectory: true)
            return ResolvedTarget(root: root, initialFile: readme(in: root), wasFile: false)
        }

        guard RepoScanner.isMarkdown(real) else { throw RootResolverError.notMarkdown }
        let file = URL(fileURLWithPath: real)
        return ResolvedTarget(root: repositoryRoot(for: file), initialFile: file, wasFile: true)
    }

    private static func readme(in root: URL) -> URL? {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? []
        return names
            .first { $0.lowercased() == "readme.md" }
            .map { root.appendingPathComponent($0) }
    }

    private static func repositoryRoot(for file: URL) -> URL {
        let parent = file.deletingLastPathComponent()
        var current = parent
        while current.path != "/" {
            if FileManager.default.fileExists(atPath: current.appendingPathComponent(".git").path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return parent
    }
}
