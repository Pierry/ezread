import XCTest
@testable import ZreadCore

final class ReaderSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "zread.tests.\(UUID().uuidString)"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testDefaultsWhenNothingSaved() {
        XCTAssertEqual(ReaderSettings.load(from: defaults), ReaderSettings())
    }

    func testRoundTrip() {
        var settings = ReaderSettings()
        settings.fontSize = 24
        settings.fontStyle = .monospaced
        settings.primaryColor = "#1A8917"
        settings.letterSpacing = 0.02
        settings.lineHeight = 1.8
        settings.save(to: defaults)
        XCTAssertEqual(ReaderSettings.load(from: defaults), settings)
    }

    func testAppearanceRoundTrip() {
        var settings = ReaderSettings()
        settings.appearance = .dark
        settings.save(to: defaults)
        XCTAssertEqual(ReaderSettings.load(from: defaults).appearance, .dark)
    }

    func testSettingsSavedBeforeAppearanceStillLoad() {
        let old = #"{"fontSize":24,"fontStyle":"medium","letterSpacing":0,"lineHeight":1.8}"#
        defaults.set(Data(old.utf8), forKey: "readerSettings")
        let loaded = ReaderSettings.load(from: defaults)
        XCTAssertEqual(loaded.fontSize, 24)
        XCTAssertNil(loaded.appearance)
    }

    func testClampsOutOfRangeValues() {
        var settings = ReaderSettings()
        settings.fontSize = 500
        settings.letterSpacing = -9
        settings.lineHeight = .nan
        let clean = settings.sanitized()
        XCTAssertEqual(clean.fontSize, 32)
        XCTAssertEqual(clean.letterSpacing, -0.05)
        XCTAssertEqual(clean.lineHeight, 1.1)
    }

    func testRejectsColorThatIsNotHex() {
        for value in ["red", "#12345", "#12345G", "#123456;x:y", "\"};alert(1)//"] {
            var settings = ReaderSettings()
            settings.primaryColor = value
            XCTAssertNil(settings.sanitized().primaryColor, value)
        }
    }

    func testAcceptsHexColor() {
        XCTAssertTrue(ReaderSettings.isValidColor("#aBc123"))
    }

    func testJavaScriptArgumentOmitsMissingColor() {
        XCTAssertFalse(ReaderSettings().javaScriptArgument().contains("primaryColor"))
    }
}
