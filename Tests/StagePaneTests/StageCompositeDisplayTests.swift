import AppKit
import StagePaneCore
import XCTest
@testable import StagePane

final class StageCompositeDisplayTests: XCTestCase {
    @MainActor
    func testCompositionAppliesNewAndChangedFramesWithoutResizing() {
        let composite = StageCompositeNSView(frame: CGRect(x: 0, y: 0, width: 800, height: 450))
        let renderer = SampleBufferRenderer(renderQueue: DispatchQueue(label: "test.composite"))
        let sourceID = StageSourceID(rawValue: "synthetic-source")
        func entry(_ frame: NormalizedStageRect) -> StageCompositeEntry {
            StageCompositeEntry(id: sourceID, frame: frame, sourceCrop: .fullSource,
                                isVisible: true, renderer: renderer)
        }

        composite.update(entries: [entry(.fullCanvas)])
        XCTAssertEqual(composite.subviews.first?.frame, composite.bounds)

        composite.update(entries: [entry(NormalizedStageRect(x: 0.25, y: 0.2, width: 0.5, height: 0.6))])
        XCTAssertEqual(composite.subviews.first?.frame, CGRect(x: 200, y: 90, width: 400, height: 270))
        XCTAssertEqual(composite.bounds.size, CGSize(width: 800, height: 450))
    }
}
