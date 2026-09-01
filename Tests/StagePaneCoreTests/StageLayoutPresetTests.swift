import XCTest
@testable import StagePaneCore

final class StageLayoutPresetTests: XCTestCase {
    private let sourceIDs = (0 ..< 10).map {
        StageSourceID(rawValue: "source-\($0)")
    }

    func testPresetCasesAreStableCodableAndSendable() throws {
        XCTAssertEqual(
            StageLayoutPreset.allCases,
            [.grid, .sideBySide, .stacked, .pictureInPicture]
        )

        for preset in StageLayoutPreset.allCases {
            let data = try JSONEncoder().encode(preset)
            XCTAssertEqual(try JSONDecoder().decode(StageLayoutPreset.self, from: data), preset)
            assertSendable(preset)
        }
    }

    func testEveryPresetIsDeterministicAndPreservesZeroThroughNineSources() {
        for preset in StageLayoutPreset.allCases {
            for count in 0 ... 9 {
                var first = makeLayout(count: count, reversedFrames: false)
                var second = makeLayout(count: count, reversedFrames: true)

                first.apply(preset: preset)
                second.apply(preset: preset)

                XCTAssertEqual(first, second, "\(preset), \(count) sources")
                XCTAssertEqual(
                    first.sources.map(\.id),
                    Array(sourceIDs.prefix(count)),
                    "\(preset), \(count) sources"
                )
                XCTAssertEqual(
                    Set(first.sources.map(\.id)).count,
                    count,
                    "\(preset), \(count) sources"
                )
                assertValidDistinctFrames(
                    first.sources.map(\.frame),
                    expectedCount: count,
                    message: "\(preset), \(count) sources"
                )
            }
        }
    }

    func testGridPresetRetainsAutomaticArrangementCompatibility() {
        for count in 0 ... 9 {
            XCTAssertEqual(
                StageLayout.frames(for: .grid, sourceCount: count),
                StageLayout.automaticFrames(count: count)
            )
        }
    }

    func testSideBySideUsesOrderedColumnsAndRequestedGaps() {
        let frames = StageLayout.frames(for: .sideBySide, sourceCount: 4)

        XCTAssertEqual(frames.count, 4)
        for (index, frame) in frames.enumerated() {
            XCTAssertEqual(frame.x, 0.02 + Double(index) * 0.245, accuracy: 0.000_000_1)
            XCTAssertEqual(frame.y, 0.02, accuracy: 0.000_000_1)
            XCTAssertEqual(frame.width, 0.225, accuracy: 0.000_000_1)
            XCTAssertEqual(frame.height, 0.96, accuracy: 0.000_000_1)
        }
    }

    func testStackedUsesOrderedRowsAndRequestedGaps() {
        let frames = StageLayout.frames(for: .stacked, sourceCount: 4)

        XCTAssertEqual(frames.count, 4)
        for (index, frame) in frames.enumerated() {
            XCTAssertEqual(frame.x, 0.02, accuracy: 0.000_000_1)
            XCTAssertEqual(frame.y, 0.02 + Double(index) * 0.245, accuracy: 0.000_000_1)
            XCTAssertEqual(frame.width, 0.96, accuracy: 0.000_000_1)
            XCTAssertEqual(frame.height, 0.225, accuracy: 0.000_000_1)
        }
    }

    func testPictureInPictureKeepsPrimaryFullAndUsesThreeReadableCorners() {
        for count in 1 ... 4 {
            let frames = StageLayout.frames(for: .pictureInPicture, sourceCount: count)
            XCTAssertEqual(frames.first, .fullCanvas)
        }

        let frames = StageLayout.frames(for: .pictureInPicture, sourceCount: 4)
        XCTAssertEqual(frames.count, 4)
        assertRect(frames[0], x: 0, y: 0, width: 1, height: 1)
        assertRect(frames[1], x: 0.62, y: 0.68, width: 0.36, height: 0.30)
        assertRect(frames[2], x: 0.02, y: 0.68, width: 0.36, height: 0.30)
        assertRect(frames[3], x: 0.62, y: 0.02, width: 0.36, height: 0.30)

        let overlays = Array(frames.dropFirst())
        for firstIndex in overlays.indices {
            for secondIndex in overlays.indices where secondIndex > firstIndex {
                XCTAssertEqual(
                    overlapArea(overlays[firstIndex], overlays[secondIndex]),
                    0,
                    accuracy: 0.000_000_1
                )
            }
        }
    }

    func testPictureInPictureFallsBackToGridForFiveOrMoreSources() {
        for count in 5 ... 9 {
            XCTAssertEqual(
                StageLayout.frames(for: .pictureInPicture, sourceCount: count),
                StageLayout.frames(for: .grid, sourceCount: count),
                "\(count) sources"
            )
        }
    }

    func testEveryPresetClampsPathologicalGaps() {
        let gaps = [-100.0, 100.0, .infinity, -.infinity, .nan]

        for preset in StageLayoutPreset.allCases {
            for gap in gaps {
                let frames = StageLayout.frames(for: preset, sourceCount: 9, gap: gap)
                assertValidDistinctFrames(
                    frames,
                    expectedCount: 9,
                    message: "\(preset), gap \(gap)"
                )
            }
            XCTAssertTrue(StageLayout.frames(for: preset, sourceCount: -1).isEmpty)
        }
    }

    private func makeLayout(count: Int, reversedFrames: Bool) -> StageLayout {
        let frames = sourceIDs.indices.map { index in
            NormalizedStageRect(
                x: 0.01 + Double(index % 5) * 0.19,
                y: 0.03 + Double(index / 5) * 0.45,
                width: 0.16,
                height: 0.32
            )
        }
        let orderedFrames = reversedFrames ? Array(frames.reversed()) : frames
        return StageLayout(sources: zip(sourceIDs.prefix(count), orderedFrames).map {
            StageSourceLayout(id: $0.0, frame: $0.1)
        })
    }

    private func assertValidDistinctFrames(
        _ frames: [NormalizedStageRect],
        expectedCount: Int,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(frames.count, expectedCount, message, file: file, line: line)
        for (index, frame) in frames.enumerated() {
            XCTAssertTrue(frame.x.isFinite, message, file: file, line: line)
            XCTAssertTrue(frame.y.isFinite, message, file: file, line: line)
            XCTAssertTrue(frame.width.isFinite, message, file: file, line: line)
            XCTAssertTrue(frame.height.isFinite, message, file: file, line: line)
            XCTAssertGreaterThanOrEqual(frame.x, 0, message, file: file, line: line)
            XCTAssertGreaterThanOrEqual(frame.y, 0, message, file: file, line: line)
            XCTAssertGreaterThan(frame.width, 0, message, file: file, line: line)
            XCTAssertGreaterThan(frame.height, 0, message, file: file, line: line)
            XCTAssertLessThanOrEqual(frame.x + frame.width, 1, message, file: file, line: line)
            XCTAssertLessThanOrEqual(frame.y + frame.height, 1, message, file: file, line: line)
            XCTAssertFalse(frames[..<index].contains(frame), message, file: file, line: line)
        }
    }

    private func overlapArea(
        _ first: NormalizedStageRect,
        _ second: NormalizedStageRect
    ) -> Double {
        let width = max(
            0,
            min(first.x + first.width, second.x + second.width) - max(first.x, second.x)
        )
        let height = max(
            0,
            min(first.y + first.height, second.y + second.height) - max(first.y, second.y)
        )
        return width * height
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
