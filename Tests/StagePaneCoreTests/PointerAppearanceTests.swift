import XCTest
@testable import StagePaneCore

final class PointerAppearanceTests: XCTestCase {
    func testPresentationDefaultsRemainStable() {
        XCTAssertEqual(PointerAppearance.presentationDefault.diameter, 22)
        XCTAssertEqual(PointerAppearance.presentationDefault.color.hexRGB, "#FF3B30")
        XCTAssertEqual(PointerAppearance.presentationDefault.glow, 0.55)
    }

    func testHexColorRoundTripsAndAcceptsWhitespace() {
        let color = PointerRGBColor(hexRGB: "  #12aBcF\n")

        XCTAssertEqual(color?.hexRGB, "#12ABCF")
    }

    func testHexColorRejectsMalformedValues() {
        XCTAssertNil(PointerRGBColor(hexRGB: "#12345"))
        XCTAssertNil(PointerRGBColor(hexRGB: "#GG0000"))
        XCTAssertNil(PointerRGBColor(hexRGB: "red"))
    }

    func testComponentsAndAppearanceValuesAreClamped() {
        let color = PointerRGBColor(red: -1, green: 0.5, blue: 2)
        let appearance = PointerAppearance(
            diameter: 1,
            color: color,
            glow: 4
        )

        XCTAssertEqual(color.hexRGB, "#0080FF")
        XCTAssertEqual(appearance.diameter, PointerAppearance.minimumDiameter)
        XCTAssertEqual(appearance.glow, PointerAppearance.maximumGlow)
    }

    func testStoredPreferencesResolveIndependently() {
        let appearance = PointerAppearance.resolvePreference(
            storedDiameter: 36,
            storedColorHex: "not-a-color",
            storedGlow: 0.2
        )

        XCTAssertEqual(appearance.diameter, 36)
        XCTAssertEqual(appearance.color, .presentationRed)
        XCTAssertEqual(appearance.glow, 0.2)
    }

    func testMissingAndNonFinitePreferencesUsePresentationDefaults() {
        XCTAssertEqual(
            PointerAppearance.resolvePreference(
                storedDiameter: nil,
                storedColorHex: nil,
                storedGlow: nil
            ),
            .presentationDefault
        )
        XCTAssertEqual(
            PointerAppearance.resolvePreference(
                storedDiameter: .infinity,
                storedColorHex: "#00FF00",
                storedGlow: .nan
            ),
            PointerAppearance(
                diameter: PointerAppearance.presentationDefault.diameter,
                color: PointerRGBColor(red: 0, green: 1, blue: 0),
                glow: PointerAppearance.presentationDefault.glow
            )
        )
    }
}
