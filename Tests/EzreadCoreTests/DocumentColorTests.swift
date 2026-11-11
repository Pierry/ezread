import XCTest
@testable import EzreadCore

final class DocumentColorTests: XCTestCase {
    private var file: URL!

    override func setUpWithError() throws {
        file = FileManager.default.temporaryDirectory.appendingPathComponent("ezread-color-\(UUID().uuidString).md")
        try "# Title\n".write(to: file, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: file)
    }

    func testNoColorByDefault() {
        XCTAssertNil(DocumentColor.read(from: file))
    }

    func testWriteAndRead() {
        XCTAssertTrue(DocumentColor.write("#1a8917", to: file))
        XCTAssertEqual(DocumentColor.read(from: file), "#1A8917")
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "# Title\n")
    }

    func testNilRemovesColor() {
        DocumentColor.write("#2F6FD0", to: file)
        XCTAssertTrue(DocumentColor.write(nil, to: file))
        XCTAssertNil(DocumentColor.read(from: file))
        XCTAssertTrue(DocumentColor.write(nil, to: file))
    }

    func testInvalidValueIsNotSaved() {
        DocumentColor.write("#2F6FD0", to: file)
        DocumentColor.write("red;x", to: file)
        XCTAssertNil(DocumentColor.read(from: file))
    }

    func testColorSurvivesSave() throws {
        DocumentColor.write("#D93025", to: file)
        let session = DocumentSession(url: file)
        try session.load()
        session.text = "# Changed\n"
        _ = try session.save()
        XCTAssertEqual(DocumentColor.read(from: file), "#D93025")
    }
}
