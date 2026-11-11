import XCTest
@testable import EzreadCore

final class WindowStateTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "ezread.tests.\(UUID().uuidString)"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testUnknownRootHasDefaults() {
        XCTAssertEqual(WindowStateStore.load(root: "/a", from: defaults), WindowState())
        XCTAssertNil(WindowStateStore.lastRoot(from: defaults))
    }

    func testRoundTrip() {
        var state = WindowState()
        state.file = "docs/a.md"
        state.line = 42
        state.sidebarVisible = false
        state.collapsedFolders = ["docs"]
        WindowStateStore.save(state, root: "/a", to: defaults)
        XCTAssertEqual(WindowStateStore.load(root: "/a", from: defaults), state)
    }

    func testRootsAreIndependentAndLastRootIsTheLatest() {
        var first = WindowState()
        first.line = 1
        var second = WindowState()
        second.line = 2
        WindowStateStore.save(first, root: "/a", to: defaults)
        WindowStateStore.save(second, root: "/b", to: defaults)
        XCTAssertEqual(WindowStateStore.load(root: "/a", from: defaults).line, 1)
        XCTAssertEqual(WindowStateStore.load(root: "/b", from: defaults).line, 2)
        XCTAssertEqual(WindowStateStore.lastRoot(from: defaults), "/b")
    }
}
