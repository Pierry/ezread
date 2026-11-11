import XCTest
@testable import EzreadCore

final class ClaudeBridgeTests: XCTestCase {
    private var directory: URL!

    private static let answer = #"{"is_error":false,"structured_output":{"summary":"S","attention":["A"],"decisions":[]}}"#

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    private func fakeClaude(_ body: String) throws -> URL {
        let url = directory.appendingPathComponent("claude")
        try "#!/bin/sh\n\(body)\n".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url
    }

    private func ask(_ bridge: ClaudeBridge, document: String = "doc") -> Result<AttentionBrief, AttentionFailure> {
        let done = expectation(description: "answer")
        var answer: Result<AttentionBrief, AttentionFailure>?
        bridge.ask(document: document) { result in
            XCTAssertTrue(Thread.isMainThread)
            answer = result
            done.fulfill()
        }
        XCTAssertTrue(bridge.isRunning)
        wait(for: [done], timeout: 20)
        XCTAssertFalse(bridge.isRunning)
        return answer!
    }

    func testReturnsTheBriefAndSendsTheDocumentOnStdin() throws {
        let received = directory.appendingPathComponent("stdin")
        let claude = try fakeClaude("cat > '\(received.path)'\necho '\(Self.answer)'")
        let result = ask(ClaudeBridge(locate: { claude }), document: "hello")
        XCTAssertEqual(try result.get(), AttentionBrief(summary: "S", attention: ["A"], decisions: []))
        XCTAssertEqual(try String(contentsOf: received, encoding: .utf8), "hello")
    }

    func testLargeDocumentDoesNotDeadlock() throws {
        let claude = try fakeClaude("cat > /dev/null\necho '\(Self.answer)'")
        let result = ask(ClaudeBridge(locate: { claude }), document: String(repeating: "x", count: 2_000_000))
        XCTAssertNoThrow(try result.get())
    }

    func testClaudeExitingWithoutReadingStdinIsNotFatal() throws {
        let claude = try fakeClaude("exit 0")
        let result = ask(ClaudeBridge(locate: { claude }), document: String(repeating: "x", count: 2_000_000))
        XCTAssertEqual(result, .failure(.unreadableAnswer))
    }

    func testMissingClaude() {
        XCTAssertEqual(ask(ClaudeBridge(locate: { nil })), .failure(.claudeNotFound))
    }

    func testUnrunnableClaudeReportsFailure() {
        let missing = directory.appendingPathComponent("nope")
        guard case .failure(.claudeFailed(let detail)) = ask(ClaudeBridge(locate: { missing })) else {
            return XCTFail("expected claudeFailed")
        }
        XCTAssertFalse(detail.isEmpty)
    }

    func testTimeout() throws {
        let claude = try fakeClaude("exec sleep 30")
        XCTAssertEqual(ask(ClaudeBridge(timeout: 0.3, locate: { claude })), .failure(.timedOut))
    }

    func testCancelledQuestionNeverAnswers() throws {
        let claude = try fakeClaude("exec sleep 30")
        let bridge = ClaudeBridge(locate: { claude })
        let silent = expectation(description: "no answer")
        silent.isInverted = true
        bridge.ask(document: "doc") { _ in silent.fulfill() }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        bridge.cancel()
        XCTAssertFalse(bridge.isRunning)
        wait(for: [silent], timeout: 0.5)
    }

    func testFirstExecutableSkipsMissingPaths() {
        XCTAssertEqual(ClaudeBridge.firstExecutable(in: ["/no/such/file", "/bin/ls"])?.path, "/bin/ls")
        XCTAssertNil(ClaudeBridge.firstExecutable(in: ["/no/such/file"]))
    }

    func testLoginShellUsesLastLine() {
        XCTAssertEqual(ClaudeBridge.executableFromLoginShell("echo banner; echo /bin/ls")?.path, "/bin/ls")
        XCTAssertNil(ClaudeBridge.executableFromLoginShell("true"))
        XCTAssertNil(ClaudeBridge.executableFromLoginShell("echo /no/such/file"))
    }

    func testFindClaudeReturnsOnlyAnExecutable() {
        if let found = ClaudeBridge.findClaude() {
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: found.path))
        }
    }

    func testEnvironmentPrependsClaudeDirectoryAndDropsNestedSessionMarker() {
        let url = URL(fileURLWithPath: "/opt/x/claude")
        let environment = ClaudeBridge.environment(for: url, base: ["PATH": "/usr/bin", "CLAUDECODE": "1", "A": "b"])
        XCTAssertEqual(environment["PATH"], "/opt/x:/opt/homebrew/bin:/usr/local/bin:/usr/bin")
        XCTAssertNil(environment["CLAUDECODE"])
        XCTAssertEqual(environment["A"], "b")
        XCTAssertEqual(
            ClaudeBridge.environment(for: url, base: [:])["PATH"],
            "/opt/x:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        )
    }

    func testFailureMessagesAreNotEmpty() {
        let failures: [AttentionFailure] = [.claudeNotFound, .claudeFailed(""), .unreadableAnswer, .timedOut]
        failures.forEach { XCTAssertFalse($0.message.isEmpty) }
        XCTAssertEqual(AttentionFailure.claudeFailed("Not logged in").message, "Not logged in")
    }

    func testBriefInitializer() {
        XCTAssertEqual(AttentionBrief(summary: "S", attention: [], decisions: ["D"]).decisions, ["D"])
    }
}
