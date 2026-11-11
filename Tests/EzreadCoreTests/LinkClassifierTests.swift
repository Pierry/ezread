import XCTest
@testable import EzreadCore

final class LinkClassifierTests: XCTestCase {
    private func classify(_ value: String) -> LinkTarget {
        LinkClassifier.classify(URL(string: value))
    }

    func testPage() {
        XCTAssertEqual(classify("ezread://app/page.html"), .page)
    }

    func testAnchor() {
        XCTAssertEqual(classify("ezread://app/page.html#part"), .anchor)
    }

    func testInternalMarkdown() {
        XCTAssertEqual(classify("ezread://root/docs/a.md"), .internalMarkdown(path: "docs/a.md", fragment: nil))
        XCTAssertEqual(classify("ezread://root/a.markdown#x"), .internalMarkdown(path: "a.markdown", fragment: "x"))
    }

    func testDecodesPercentEscapes() {
        XCTAssertEqual(classify("ezread://root/my%20docs/a.md"), .internalMarkdown(path: "my docs/a.md", fragment: nil))
    }

    func testExternal() {
        for value in ["http://a.b", "https://a.b/c.md", "mailto:a@b.c"] {
            XCTAssertEqual(classify(value), .external)
        }
    }

    func testBlocked() {
        for value in ["ezread://root/a.pdf", "ezread://app/reader.js", "ezread://other/a.md", "file:///etc/passwd", "javascript:alert(1)", "ftp://a.b"] {
            XCTAssertEqual(classify(value), .blocked, value)
        }
        XCTAssertEqual(LinkClassifier.classify(nil), .blocked)
    }
}
