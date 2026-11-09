import XCTest
@testable import ZreadCore

final class MarkdownRendererTests: XCTestCase {
    func testDropsRawHTML() {
        let html = MarkdownRenderer.render(markdown: "<script>alert(1)</script>\n\ntext").html
        XCTAssertFalse(html.contains("<script"))
        XCTAssertTrue(html.contains("text"))
    }

    func testDropsInlineRawHTML() {
        let html = MarkdownRenderer.render(markdown: "a <img src=x onerror=alert(1)> b").html
        XCTAssertFalse(html.contains("onerror"))
    }

    func testBlocksHaveSourcePositions() {
        let html = MarkdownRenderer.render(markdown: "# Title\n\nParagraph").html
        XCTAssertTrue(html.contains("<h1 data-sourcepos=\"1:1"))
        XCTAssertTrue(html.contains("<p data-sourcepos=\"3:1"))
    }

    func testTablesAndTaskLists() {
        let html = MarkdownRenderer.render(markdown: "|a|b|\n|-|-|\n|1|2|\n\n- [x] done").html
        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("type=\"checkbox\""))
    }

    func testHasCodeOnlyWithLanguage() {
        XCTAssertTrue(MarkdownRenderer.render(markdown: "```swift\nlet a = 1\n```").hasCode)
        XCTAssertFalse(MarkdownRenderer.render(markdown: "```\nplain\n```").hasCode)
        XCTAssertFalse(MarkdownRenderer.render(markdown: "text").hasCode)
    }

    func testRewritesRelativeImageInSubfolder() {
        let html = MarkdownRenderer.render(markdown: "![x](img/a.png)", documentDirectory: "docs").html
        XCTAssertTrue(html.contains("src=\"zread://root/docs/img/a.png\""))
    }

    func testRewritesRelativeLinkKeepingFragment() {
        let html = MarkdownRenderer.render(markdown: "[x](other.md#part)", documentDirectory: "docs").html
        XCTAssertTrue(html.contains("href=\"zread://root/docs/other.md#part\""))
    }

    func testEncodesSpacesInDocumentDirectory() {
        XCTAssertEqual(
            MarkdownRenderer.rewrite(url: "a.md", documentDirectory: "my docs"),
            "zread://root/my%20docs/a.md"
        )
    }

    func testRootAbsoluteLink() {
        XCTAssertEqual(MarkdownRenderer.rewrite(url: "/a.md", documentDirectory: "docs"), "zread://root/a.md")
    }

    func testLeavesExternalAndAnchorLinks() {
        for url in ["https://example.com/a.md", "mailto:a@b.c", "#part"] {
            XCTAssertEqual(MarkdownRenderer.rewrite(url: url, documentDirectory: "docs"), url)
        }
    }

    func testDangerousSchemeIsNotRendered() {
        let html = MarkdownRenderer.render(markdown: "[x](javascript:alert(1))").html
        XCTAssertFalse(html.contains("javascript:"))
    }
}
