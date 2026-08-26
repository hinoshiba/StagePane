import XCTest
@testable import StagePaneCore

final class StageLayoutTests: XCTestCase {
    private let sourceA = StageSourceID(rawValue: "source-a")
    private let sourceB = StageSourceID(rawValue: "source-b")
    private let sourceC = StageSourceID(rawValue: "source-c")
    private let sourceD = StageSourceID(rawValue: "source-d")

    func testSingleSourceFillsCanvas() {
        let layout = StageLayout(automaticallyArranging: [sourceA])

        XCTAssertEqual(layout.sources, [
            StageSourceLayout(id: sourceA, frame: .fullCanvas)
        ])
    }

    func testAutomaticLayoutIsDeterministicAndRowMajor() {
        let sourceIDs = [sourceA, sourceB, sourceC, sourceD]
        let first = StageLayout(automaticallyArranging: sourceIDs)
        let second = StageLayout(automaticallyArranging: sourceIDs)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.sources.map(\.id), sourceIDs)
        assertRect(first.sources[0].frame, x: 0.02, y: 0.02, width: 0.47, height: 0.47)
        assertRect(first.sources[1].frame, x: 0.51, y: 0.02, width: 0.47, height: 0.47)
        assertRect(first.sources[2].frame, x: 0.02, y: 0.51, width: 0.47, height: 0.47)
        assertRect(first.sources[3].frame, x: 0.51, y: 0.51, width: 0.47, height: 0.47)
    }

    func testDuplicateIDsAreIgnoredWithoutChangingOrder() {
        let layout = StageLayout(automaticallyArranging: [sourceA, sourceB, sourceA, sourceC])

        XCTAssertEqual(layout.sources.map(\.id), [sourceA, sourceB, sourceC])
    }

    func testLayerListOrderIsFrontToBackAndBringToFrontKeepsFrames() {
        let frameA = NormalizedStageRect(x: 0, y: 0, width: 0.7, height: 0.7)
        let frameB = NormalizedStageRect(x: 0.1, y: 0.1, width: 0.7, height: 0.7)
        let frameC = NormalizedStageRect(x: 0.2, y: 0.2, width: 0.7, height: 0.7)
        var layout = StageLayout(sources: [
            StageSourceLayout(id: sourceA, frame: frameA),
            StageSourceLayout(id: sourceB, frame: frameB),
            StageSourceLayout(id: sourceC, frame: frameC)
        ])

        XCTAssertEqual(layout.sources.map(\.id), [sourceA, sourceB, sourceC])
        XCTAssertEqual(layout.frontToBackSources.map(\.id), [sourceC, sourceB, sourceA])

        XCTAssertTrue(layout.bringSourceToFront(sourceA))
        XCTAssertEqual(layout.sources.map(\.id), [sourceB, sourceC, sourceA])
        XCTAssertEqual(layout.frontToBackSources.map(\.id), [sourceA, sourceC, sourceB])
        XCTAssertEqual(layout[sourceID: sourceA]?.frame, frameA)
        XCTAssertFalse(layout.bringSourceToFront(sourceA))
        XCTAssertFalse(layout.bringSourceToFront(StageSourceID(rawValue: "missing")))
    }

    func testAddRearrangesAndExplicitAddPreservesExistingFrame() {
        var layout = StageLayout(automaticallyArranging: [sourceA])

        XCTAssertTrue(layout.addSource(sourceB))
        XCTAssertEqual(layout.sources.map(\.id), [sourceA, sourceB])
        XCTAssertNotEqual(layout[sourceID: sourceA]?.frame, .fullCanvas)

        let existingFrame = layout[sourceID: sourceA]?.frame
        let customFrame = NormalizedStageRect(x: 0.6, y: 0.6, width: 0.3, height: 0.25)
        XCTAssertTrue(layout.addSource(sourceC, frame: customFrame))
        XCTAssertEqual(layout[sourceID: sourceA]?.frame, existingFrame)
        XCTAssertEqual(layout[sourceID: sourceC]?.frame, customFrame)
        XCTAssertFalse(layout.addSource(sourceC))
    }

    func testRectAndDragAreClampedToCanvas() {
        let clamped = NormalizedStageRect(x: 0.9, y: -0.2, width: 0.5, height: 1.4)
        assertRect(clamped, x: 0.5, y: 0, width: 0.5, height: 1)

        var layout = StageLayout(sources: [StageSourceLayout(id: sourceA, frame: clamped)])
        XCTAssertTrue(layout.moveSource(sourceA, byX: -2, y: 4))
        assertRect(layout[sourceID: sourceA]!.frame, x: 0, y: 0, width: 0.5, height: 1)

        XCTAssertTrue(layout.moveSource(sourceA, byX: 2, y: -.infinity))
        assertRect(layout[sourceID: sourceA]!.frame, x: 0.5, y: 0, width: 0.5, height: 1)
    }

    func testResizeEnforcesMinimumWithoutLockingAspectRatio() {
        var layout = StageLayout(sources: [
            StageSourceLayout(
                id: sourceA,
                frame: NormalizedStageRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
            )
        ])

        XCTAssertTrue(layout.resizeSource(
            sourceA,
            x: 0.98,
            y: -0.5,
            width: 0.01,
            height: 2,
            minimumWidth: 0.1,
            minimumHeight: 0.2
        ))

        let frame = layout[sourceID: sourceA]!.frame
        assertRect(frame, x: 0.9, y: 0, width: 0.1, height: 1)
        XCTAssertNotEqual(frame.width / frame.height, 1, accuracy: 0.0001)
    }

    func testResizeKeepsValidTopLeftAnchorAtCanvasEdge() {
        var layout = StageLayout(sources: [
            StageSourceLayout(
                id: sourceA,
                frame: NormalizedStageRect(x: 0.5, y: 0.4, width: 0.4, height: 0.3)
            )
        ])

        XCTAssertTrue(layout.resizeSource(
            sourceA,
            x: 0.5,
            y: 0.4,
            width: 0.8,
            height: 0.9,
            minimumWidth: 0.1,
            minimumHeight: 0.1
        ))
        assertRect(layout[sourceID: sourceA]!.frame, x: 0.5, y: 0.4, width: 0.5, height: 0.6)
    }

    func testSuggestedFramesDoNotRequireMovingExistingSources() {
        XCTAssertEqual(StageLayout.suggestedFrameForNewSource(occupiedFrames: []), .fullCanvas)
        let fullCanvas = [NormalizedStageRect.fullCanvas]
        assertRect(
            StageLayout.suggestedFrameForNewSource(occupiedFrames: fullCanvas),
            x: 0.52,
            y: 0.52,
            width: 0.46,
            height: 0.46
        )
        let bottomRight = NormalizedStageRect(x: 0.52, y: 0.52, width: 0.46, height: 0.46)
        assertRect(
            StageLayout.suggestedFrameForNewSource(
                occupiedFrames: fullCanvas + [bottomRight]
            ),
            x: 0.02,
            y: 0.52,
            width: 0.46,
            height: 0.46
        )
    }

    func testSuggestedFrameReusesTheLeastOccupiedCornerAfterRemoval() {
        let occupied = [
            NormalizedStageRect.fullCanvas,
            NormalizedStageRect(x: 0.02, y: 0.52, width: 0.46, height: 0.46),
            NormalizedStageRect(x: 0.52, y: 0.02, width: 0.46, height: 0.46)
        ]

        assertRect(
            StageLayout.suggestedFrameForNewSource(occupiedFrames: occupied),
            x: 0.52,
            y: 0.52,
            width: 0.46,
            height: 0.46
        )
    }

    func testSuggestedFramesScaleBeyondFourWithoutExactDuplicates() {
        var occupied = [NormalizedStageRect.fullCanvas]

        for _ in 1 ..< 12 {
            let frame = StageLayout.suggestedFrameForNewSource(occupiedFrames: occupied)
            XCTAssertFalse(occupied.contains(frame))
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
            XCTAssertGreaterThanOrEqual(frame.x, 0)
            XCTAssertGreaterThanOrEqual(frame.y, 0)
            XCTAssertLessThanOrEqual(frame.x + frame.width, 1)
            XCTAssertLessThanOrEqual(frame.y + frame.height, 1)
            occupied.append(frame)
        }
    }

    func testAutomaticAndPictureInPictureLayoutsScaleBeyondFourSources() {
        let sourceIDs = (0 ..< 9).map { StageSourceID(rawValue: "source-\($0)") }
        let automatic = StageLayout(automaticallyArranging: sourceIDs)

        XCTAssertEqual(automatic.sources.count, 9)
        XCTAssertTrue(automatic.sources.allSatisfy { source in
            source.frame.width > 0 && source.frame.height > 0 &&
                source.frame.x >= 0 && source.frame.y >= 0 &&
                source.frame.x + source.frame.width <= 1 &&
                source.frame.y + source.frame.height <= 1
        })

        var pictureInPicture = StageLayout(sources: automatic.sources)
        pictureInPicture.apply(preset: .pictureInPicture)
        XCTAssertEqual(
            pictureInPicture.sources.map(\.frame),
            StageLayout.automaticFrames(count: sourceIDs.count)
        )
        XCTAssertEqual(pictureInPicture.sources.map(\.id), sourceIDs)
    }

    func testRemovePreservesRemainingFrame() {
        let retainedFrame = NormalizedStageRect(x: 0.4, y: 0.1, width: 0.5, height: 0.7)
        var layout = StageLayout(sources: [
            StageSourceLayout(id: sourceA, frame: .fullCanvas),
            StageSourceLayout(id: sourceB, frame: retainedFrame)
        ])

        XCTAssertTrue(layout.removeSource(sourceA))
        XCTAssertEqual(layout.sources, [StageSourceLayout(id: sourceB, frame: retainedFrame)])
        XCTAssertFalse(layout.removeSource(sourceC))
    }

    func testCodableRoundTripRetainsIDsOrderAndFrames() throws {
        let layout = StageLayout(automaticallyArranging: [sourceA, sourceB, sourceC])

        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(StageLayout.self, from: data)

        XCTAssertEqual(decoded, layout)
        assertSendable(decoded)
    }

    func testDecodedRectIsClamped() throws {
        let data = Data(#"{"x":2,"y":-1,"width":2,"height":0}"#.utf8)

        let decoded = try JSONDecoder().decode(NormalizedStageRect.self, from: data)

        XCTAssertEqual(decoded.x, 0)
        XCTAssertEqual(decoded.y, 0)
        XCTAssertEqual(decoded.width, 1)
        XCTAssertEqual(decoded.height, Double.ulpOfOne)
    }

    private func assertRect(
        _ rect: NormalizedStageRect,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(rect.x, x, accuracy: 0.000_000_1, file: file, line: line)
        XCTAssertEqual(rect.y, y, accuracy: 0.000_000_1, file: file, line: line)
        XCTAssertEqual(rect.width, width, accuracy: 0.000_000_1, file: file, line: line)
        XCTAssertEqual(rect.height, height, accuracy: 0.000_000_1, file: file, line: line)
    }

    private func assertSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
