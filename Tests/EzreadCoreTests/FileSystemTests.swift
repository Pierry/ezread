import XCTest
@testable import EzreadCore

class TemporaryDirectoryTestCase: XCTestCase {
    var directory: URL!

    override func setUpWithError() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        directory = URL(fileURLWithPath: PathGuard.realPath(base.path)!, isDirectory: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func write(_ path: String, _ text: String = "x") throws {
        let url = directory.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func git(_ arguments: String...) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = directory
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }

    func flatten(_ nodes: [FileNode]) -> [String] {
        nodes.flatMap { node in
            node.isDirectory ? flatten(node.children!) : [node.relativePath]
        }
    }
}

final class RepoScannerTests: TemporaryDirectoryTestCase {
    func testGitRespectsIgnoreAndIncludesUntracked() throws {
        try git("init", "-q")
        try write(".gitignore", "ignored/\n")
        try write("README.md")
        try write("docs/a.markdown")
        try write("docs/UPPER.MD")
        try write("ignored/b.md")
        try write("code.swift")

        XCTAssertEqual(Set(flatten(RepoScanner.scanSync(root: directory))), ["README.md", "docs/a.markdown", "docs/UPPER.MD"])
    }

    func testGitHidesNodeModulesWithoutIgnoreRule() throws {
        try git("init", "-q")
        try write("README.md")
        try write("node_modules/pkg/readme.md")

        XCTAssertEqual(flatten(RepoScanner.scanSync(root: directory)), ["README.md"])
    }

    func testWalkFallbackWithoutGit() throws {
        try write("README.md")
        try write("docs/a.md")
        try write("node_modules/pkg/readme.md")
        try write(".git/x.md")
        try write("code.swift")

        XCTAssertEqual(Set(flatten(RepoScanner.scanSync(root: directory))), ["README.md", "docs/a.md"])
    }

    func testFoldersWithoutMarkdownDoNotAppear() throws {
        try write("README.md")
        try write("src/main.swift")

        XCTAssertEqual(RepoScanner.scanSync(root: directory).map(\.name), ["README.md"])
    }
}

final class RootResolverTests: TemporaryDirectoryTestCase {
    func testFolderUsesReadme() throws {
        try write("README.md")
        let target = try RootResolver.resolve(path: directory.path)
        XCTAssertEqual(target.root.path, directory.path)
        XCTAssertEqual(target.initialFile?.lastPathComponent, "README.md")
    }

    func testFolderWithoutReadme() throws {
        try write("notes.md")
        XCTAssertNil(try RootResolver.resolve(path: directory.path).initialFile)
    }

    func testFileInsideGitRepositoryUsesRepositoryRoot() throws {
        try git("init", "-q")
        try write("docs/deep/a.md")
        let target = try RootResolver.resolve(path: directory.appendingPathComponent("docs/deep/a.md").path)
        XCTAssertEqual(target.root.path, directory.path)
    }

    func testFileOutsideGitUsesParent() throws {
        try write("docs/a.md")
        let target = try RootResolver.resolve(path: directory.appendingPathComponent("docs/a.md").path)
        XCTAssertEqual(target.root.path, directory.appendingPathComponent("docs").path)
    }

    func testErrors() throws {
        try write("a.txt")
        XCTAssertThrowsError(try RootResolver.resolve(path: directory.appendingPathComponent("a.txt").path)) {
            XCTAssertEqual($0 as? RootResolverError, .notMarkdown)
        }
        XCTAssertThrowsError(try RootResolver.resolve(path: directory.appendingPathComponent("none").path)) {
            XCTAssertEqual($0 as? RootResolverError, .notFound)
        }
    }
}

final class PathGuardTests: TemporaryDirectoryTestCase {
    private var root: URL { directory.appendingPathComponent("root") }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try write("root/in.png")
        try write("outside.png")
    }

    func testAllowsInsideRoot() {
        XCTAssertEqual(PathGuard.resolve(relativePath: "in.png", root: root)?.lastPathComponent, "in.png")
    }

    func testRejectsParentTraversal() {
        XCTAssertNil(PathGuard.resolve(relativePath: "../outside.png", root: root))
    }

    func testRejectsSymlinkLeavingRoot() throws {
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("link.png"),
            withDestinationURL: directory.appendingPathComponent("outside.png")
        )
        XCTAssertNil(PathGuard.resolve(relativePath: "link.png", root: root))
    }

    func testRejectsSiblingWithSamePrefix() throws {
        try write("root-other/a.png")
        XCTAssertNil(PathGuard.resolve(relativePath: "../root-other/a.png", root: root))
    }

    func testRejectsMissingFile() {
        XCTAssertNil(PathGuard.resolve(relativePath: "none.png", root: root))
    }
}

final class DocumentSessionTests: TemporaryDirectoryTestCase {
    private var file: URL { directory.appendingPathComponent("a.md") }

    func testEditMakesDirtyAndSaveClears() throws {
        try write("a.md", "old")
        let session = DocumentSession(url: file)
        try session.load()
        XCTAssertFalse(session.isDirty)

        session.text = "new"
        XCTAssertTrue(session.isDirty)
        XCTAssertEqual(try session.save(), .saved)
        XCTAssertFalse(session.isDirty)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "new")
    }

    func testSaveReportsConflictAndKeepsDisk() throws {
        try write("a.md", "old")
        let session = DocumentSession(url: file)
        try session.load()
        try changeOnDisk("external")

        session.text = "mine"
        XCTAssertTrue(session.changedOnDisk())
        XCTAssertEqual(try session.save(), .conflict)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "external")
        XCTAssertTrue(session.isDirty)
    }

    func testForceSaveOverwrites() throws {
        try write("a.md", "old")
        let session = DocumentSession(url: file)
        try session.load()
        try changeOnDisk("external")

        session.text = "mine"
        XCTAssertEqual(try session.save(force: true), .saved)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "mine")
        XCTAssertFalse(session.changedOnDisk())
    }

    func testSaveKeepsPermissions() throws {
        try write("a.md", "old")
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        let session = DocumentSession(url: file)
        try session.load()
        session.text = "new"
        _ = try session.save()

        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    }

    func testMissingFileIsNotReportedAsChanged() throws {
        try write("a.md", "old")
        let session = DocumentSession(url: file)
        try session.load()
        try FileManager.default.removeItem(at: file)
        XCTAssertFalse(session.changedOnDisk())
    }

    private func changeOnDisk(_ text: String) throws {
        try text.write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: 60)], ofItemAtPath: file.path)
    }
}
