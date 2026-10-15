import XCTest
@testable import StagePaneCore

final class StageLayerNameTests: XCTestCase {
    func testUnnamedLayerFollowsItsCurrentSource() {
        var name = StageLayerName(defaultTitle: "Keynote — Slides")

        XCTAssertNil(name.customName)
        XCTAssertEqual(name.displayTitle, "Keynote — Slides")

        name.defaultTitle = "Safari — Demo"

        XCTAssertEqual(name.displayTitle, "Safari — Demo")
    }

    func testCustomNameSurvivesReplacingOrReconnectingSource() {
        var name = StageLayerName(defaultTitle: "Window 1")
        name.rename(to: "発表資料")

        name.defaultTitle = "Keynote — Updated Slides"

        XCTAssertEqual(name.customName, "発表資料")
        XCTAssertEqual(name.displayTitle, "発表資料")
        XCTAssertEqual(name.defaultTitle, "Keynote — Updated Slides")
    }

    func testBlankNameRestoresLatestAutomaticSourceTitle() {
        var name = StageLayerName(defaultTitle: "Window 1", customName: "Demo")
        name.defaultTitle = "Safari — Demo"

        name.rename(to: " \t\n\u{3000} ")

        XCTAssertNil(name.customName)
        XCTAssertEqual(name.displayTitle, "Safari — Demo")
    }

    func testPastedWhitespaceProducesSingleLineName() {
        var name = StageLayerName(defaultTitle: "Window 1")

        name.rename(to: "  Live\t demo\r\n 第２部\u{3000} ")

        XCTAssertEqual(name.customName, "Live demo 第２部")
        XCTAssertEqual(name.displayTitle, "Live demo 第２部")
    }

    func testNamesPreserveUnicodeCharactersAndPunctuation() {
        let customName = "🧑🏽‍💻 デモ — café (2)"
        let name = StageLayerName(defaultTitle: "Window 1", customName: customName)

        XCTAssertEqual(name.customName, customName)
        XCTAssertEqual(name.displayTitle, customName)
    }

    func testInitializerUsesSameNormalizationAsRename() {
        let initialized = StageLayerName(defaultTitle: "Window 1", customName: "  Demo\n screen  ")
        var renamed = StageLayerName(defaultTitle: "Window 1")
        renamed.rename(to: "  Demo\n screen  ")

        XCTAssertEqual(initialized, renamed)
        XCTAssertNil(StageLayerName(defaultTitle: "Window 1", customName: "  ").customName)
    }
}
