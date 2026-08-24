import CoreGraphics
import Foundation
import XCTest
@testable import StagePaneCore

final class StageAnnotationsTests: XCTestCase {
    func testPointNormalizesAndClampsCanvasCoordinates() throws {
        let point = try XCTUnwrap(StageAnnotationPoint(
            point: CGPoint(x: 300, y: -10),
            in: CGSize(width: 200, height: 100),
            pressure: 2
        ))

        XCTAssertEqual(point, StageAnnotationPoint(x: 1, y: 0, pressure: 1))
        XCTAssertEqual(
            point.point(in: CGSize(width: 1920, height: 1080)),
            CGPoint(x: 1920, y: 0)
        )
        XCTAssertNil(StageAnnotationPoint(
            point: .zero,
            in: .zero
        ))
    }

    func testInkStyleScalesAgainstShortCanvasDimension() {
        let style = StageInkStyle(color: .red, normalizedWidth: 0.01)

        XCTAssertEqual(style.lineWidth(in: CGSize(width: 1920, height: 1080)), 10.8)
        XCTAssertEqual(style.lineWidth(in: CGSize(width: 540, height: 960)), 5.4)
        XCTAssertEqual(
            StageInkStyle(color: .red, normalizedWidth: 1).normalizedWidth,
            StageInkStyle.maximumNormalizedWidth
        )
    }

    func testInkPreferencesResolvePenAndHighlighterStyles() {
        let pen = StageInkPreferences(
            tool: .pen,
            colorPreset: .blue,
            normalizedWidth: 0.012
        )
        let highlighter = StageInkPreferences(
            tool: .highlighter,
            colorPreset: .yellow,
            normalizedWidth: 0.02
        )

        XCTAssertEqual(pen.style.color, StageInkColorPreset.blue.color)
        XCTAssertEqual(pen.style.normalizedWidth, 0.012)
        XCTAssertEqual(
            highlighter.style.color,
            StageInkColor(red: 1, green: 0.78, blue: 0.05, alpha: 0.36)
        )
        XCTAssertEqual(highlighter.style.normalizedWidth, 0.02)

        var document = StageAnnotationDocument()
        XCTAssertTrue(document.beginStroke(
            at: StageAnnotationPoint(x: 0.5, y: 0.5),
            style: highlighter.style
        ))
        XCTAssertEqual(document.strokes.last?.style, highlighter.style)
    }

    func testEraserPreferencesUseASeparateSanitizedWidth() throws {
        let eraser = StageInkPreferences(
            tool: .eraser,
            colorPreset: .blue,
            normalizedWidth: 0.006,
            eraserNormalizedWidth: 0.03
        )

        XCTAssertEqual(eraser.tool.strokeKind, .eraser)
        XCTAssertEqual(eraser.style.normalizedWidth, 0.03)
        XCTAssertEqual(eraser.style.color.alpha, 0)
        XCTAssertEqual(
            eraser.style.lineWidth(in: CGSize(width: 1920, height: 1080)),
            32.4
        )

        let tooSmall = StageInkPreferences(
            tool: .eraser,
            colorPreset: .red,
            normalizedWidth: 0.006,
            eraserNormalizedWidth: -1
        )
        let tooLarge = StageInkPreferences(
            tool: .eraser,
            colorPreset: .red,
            normalizedWidth: 0.006,
            eraserNormalizedWidth: 1
        )
        let nonFinite = StageInkPreferences(
            tool: .eraser,
            colorPreset: .red,
            normalizedWidth: 0.006,
            eraserNormalizedWidth: .infinity
        )
        XCTAssertEqual(
            tooSmall.eraserNormalizedWidth,
            StageInkPreferences.minimumEraserNormalizedWidth
        )
        XCTAssertEqual(
            tooLarge.eraserNormalizedWidth,
            StageInkPreferences.maximumEraserNormalizedWidth
        )
        XCTAssertEqual(
            nonFinite.eraserNormalizedWidth,
            StageInkPreferences.defaultEraserNormalizedWidth
        )

        let legacyData = Data(
            #"{"tool":"pen","colorPreset":"blue","normalizedWidth":0.01}"#.utf8
        )
        let legacy = try JSONDecoder().decode(StageInkPreferences.self, from: legacyData)
        XCTAssertEqual(
            legacy.eraserNormalizedWidth,
            StageInkPreferences.defaultEraserNormalizedWidth
        )
        XCTAssertEqual(
            try JSONDecoder().decode(
                StageInkPreferences.self,
                from: JSONEncoder().encode(eraser)
            ),
            eraser
        )
    }

    func testInkPreferencesClampWidthAndRoundTrip() throws {
        XCTAssertEqual(StageInkPreferences.defaultPreferences.tool, .pen)
        XCTAssertEqual(StageInkPreferences.defaultPreferences.colorPreset, .red)
        XCTAssertEqual(
            StageInkPreferences.defaultPreferences.normalizedWidth,
            StageInkStyle.defaultStyle.normalizedWidth
        )

        let tooNarrow = StageInkPreferences(
            tool: .pen,
            colorPreset: .red,
            normalizedWidth: -1
        )
        let tooWide = StageInkPreferences(
            tool: .highlighter,
            colorPreset: .white,
            normalizedWidth: 1
        )
        let nonFinite = StageInkPreferences(
            tool: .pen,
            colorPreset: .green,
            normalizedWidth: .infinity
        )

        XCTAssertEqual(
            tooNarrow.normalizedWidth,
            StageInkPreferences.minimumNormalizedWidth
        )
        XCTAssertEqual(
            tooWide.normalizedWidth,
            StageInkPreferences.maximumNormalizedWidth
        )
        XCTAssertEqual(
            nonFinite.normalizedWidth,
            StageInkStyle.defaultStyle.normalizedWidth
        )

        let data = try JSONEncoder().encode(tooNarrow)
        XCTAssertEqual(
            try JSONDecoder().decode(StageInkPreferences.self, from: data),
            tooNarrow
        )
        let decodedWide = try JSONDecoder().decode(
            StageInkPreferences.self,
            from: Data(
                #"{"tool":"pen","colorPreset":"blue","normalizedWidth":1}"#.utf8
            )
        )
        XCTAssertEqual(
            decodedWide.normalizedWidth,
            StageInkPreferences.maximumNormalizedWidth
        )
        assertSendable(tooNarrow)
    }

    func testDocumentBuildsOrderedStrokesAndSkipsDuplicatePoints() {
        let strokeID = UUID(uuidString: "C49780EE-84A1-4E16-BC29-E33F8306F8D7")!
        let first = StageAnnotationPoint(x: 0.1, y: 0.2)
        let second = StageAnnotationPoint(x: 0.3, y: 0.4, pressure: 0.5)
        var document = StageAnnotationDocument()

        XCTAssertTrue(document.beginStroke(id: strokeID, at: first))
        XCTAssertFalse(document.beginStroke(id: strokeID, at: second))
        XCTAssertFalse(document.append(first, to: strokeID))
        XCTAssertTrue(document.append(second, to: strokeID))
        XCTAssertEqual(document.strokes.first?.points, [first, second])
        XCTAssertTrue(document.removeStroke(strokeID))
        XCTAssertFalse(document.removeStroke(strokeID))
    }

    func testDocumentDropsDuplicateStrokeIDsAndRoundTrips() throws {
        let strokeID = UUID(uuidString: "BE74E0A8-AFF9-45FE-8716-A936DBBA5682")!
        let first = StageAnnotationStroke(
            id: strokeID,
            points: [StageAnnotationPoint(x: 0, y: 0)]
        )
        let duplicate = StageAnnotationStroke(
            id: strokeID,
            points: [StageAnnotationPoint(x: 1, y: 1)]
        )
        let document = StageAnnotationDocument(strokes: [first, duplicate])

        XCTAssertEqual(document.strokes, [first])
        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(StageAnnotationDocument.self, from: data)
        XCTAssertEqual(decoded, document)
        assertSendable(decoded)
    }

    func testEraserStrokePreservesActionOrderAndLegacyStrokeDefaultsToInk() throws {
        let inkID = UUID(uuidString: "A39B4679-BAB4-4B49-A0C9-6BA4FD533300")!
        let eraserID = UUID(uuidString: "C7C45863-BF09-45D8-969D-8187E5CF7C9C")!
        var document = StageAnnotationDocument()
        XCTAssertFalse(document.containsInkStroke)
        XCTAssertFalse(document.beginStroke(
            id: eraserID,
            at: StageAnnotationPoint(x: 0.2, y: 0.2),
            kind: .eraser
        ))
        XCTAssertTrue(document.beginStroke(
            id: inkID,
            at: StageAnnotationPoint(x: 0.1, y: 0.1),
            kind: .ink
        ))
        XCTAssertTrue(document.beginStroke(
            id: eraserID,
            at: StageAnnotationPoint(x: 0.2, y: 0.2),
            kind: .eraser,
            style: StageInkStyle(
                color: StageInkColor(red: 1, green: 1, blue: 1, alpha: 0),
                normalizedWidth: 0.03
            )
        ))
        XCTAssertEqual(document.strokes.map(\.kind), [.ink, .eraser])
        XCTAssertTrue(document.containsInkStroke)

        let encoded = try JSONEncoder().encode(document)
        XCTAssertEqual(
            try JSONDecoder().decode(StageAnnotationDocument.self, from: encoded),
            document
        )
        XCTAssertTrue(document.removeStroke(eraserID))
        XCTAssertEqual(document.strokes.map(\.id), [inkID])

        let legacyStrokeData = Data(
            #"{"id":"A39B4679-BAB4-4B49-A0C9-6BA4FD533300","style":{"color":{"red":1,"green":0,"blue":0,"alpha":1},"normalizedWidth":0.006},"points":[{"x":0.1,"y":0.2,"pressure":1}]}"#.utf8
        )
        let legacyStroke = try JSONDecoder().decode(
            StageAnnotationStroke.self,
            from: legacyStrokeData
        )
        XCTAssertEqual(legacyStroke.kind, .ink)
    }

    func testDecodedValuesAreSanitized() throws {
        let pointData = Data(#"{"x":2,"y":-1,"pressure":3}"#.utf8)
        let point = try JSONDecoder().decode(StageAnnotationPoint.self, from: pointData)
        XCTAssertEqual(point, StageAnnotationPoint(x: 1, y: 0, pressure: 1))

        let styleData = Data(
            #"{"color":{"red":2,"green":-1,"blue":0.5,"alpha":4},"normalizedWidth":2}"#.utf8
        )
        let style = try JSONDecoder().decode(StageInkStyle.self, from: styleData)
        XCTAssertEqual(style.color, StageInkColor(red: 1, green: 0, blue: 0.5, alpha: 1))
        XCTAssertEqual(style.normalizedWidth, StageInkStyle.maximumNormalizedWidth)
    }

    private func assertSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
