import XCTest
@testable import EzreadCore

final class AttentionBriefTests: XCTestCase {
    private func parse(_ json: String) throws -> AttentionBrief {
        try AttentionRequest.parse(Data(json.utf8))
    }

    func testReadsStructuredOutput() throws {
        let brief = try parse("""
        {"type":"result","is_error":false,"result":"x",
         "structured_output":{"summary":"S","attention":["A"],"decisions":["D"]}}
        """)
        XCTAssertEqual(brief, AttentionBrief(summary: "S", attention: ["A"], decisions: ["D"]))
    }

    func testReportsClaudeError() {
        XCTAssertThrowsError(try parse(#"{"is_error":true,"result":"Not logged in"}"#)) { error in
            XCTAssertEqual(error as? AttentionFailure, .claudeFailed("Not logged in"))
        }
    }

    func testRejectsAnswerWithoutStructuredOutput() {
        XCTAssertThrowsError(try parse(#"{"is_error":false,"result":"plain text"}"#)) { error in
            XCTAssertEqual(error as? AttentionFailure, .unreadableAnswer)
        }
    }

    func testRejectsNonJSON() {
        XCTAssertThrowsError(try parse("command failed")) { error in
            XCTAssertEqual(error as? AttentionFailure, .unreadableAnswer)
        }
    }

    func testRunsWithoutTools() {
        let arguments = AttentionRequest.arguments
        let index = arguments.firstIndex(of: "--tools")
        XCTAssertEqual(index.map { arguments[$0 + 1] }, "")
    }
}
