import Foundation

public enum SaveResult: Equatable {
    case saved
    case conflict
}

public final class DocumentSession {
    public let url: URL
    public var text: String = ""
    private var savedText: String = ""
    private var loadedModificationDate: Date?

    public init(url: URL) {
        self.url = url
    }

    public var isDirty: Bool { text != savedText }

    public func load() throws {
        let contents = try String(contentsOf: url, encoding: .utf8)
        text = contents
        savedText = contents
        loadedModificationDate = modificationDate()
    }

    /// True when the file on disk differs from the version that was loaded.
    /// A missing file reports false, so the document stays on screen.
    public func changedOnDisk() -> Bool {
        guard let current = modificationDate() else { return false }
        return current != loadedModificationDate
    }

    /// Writes atomically. Returns `.conflict` without writing if the file
    /// changed on disk, unless `force` is true.
    public func save(force: Bool = false) throws -> SaveResult {
        if !force && changedOnDisk() { return .conflict }

        let permissions = try? FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions]
        // An atomic write replaces the file and would drop its attributes.
        let color = DocumentColor.read(from: url)
        try text.write(to: url, atomically: true, encoding: .utf8)
        if let color { DocumentColor.write(color, to: url) }
        if let permissions {
            try? FileManager.default.setAttributes([.posixPermissions: permissions as Any], ofItemAtPath: url.path)
        }
        savedText = text
        loadedModificationDate = modificationDate()
        return .saved
    }

    private func modificationDate() -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }
}
