import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit
import StagePaneCore
import XCTest
@testable import StagePane

final class StageCompositePresentationTests: XCTestCase {
    /// The fully initialized buffer is immutable after it crosses to the
    /// renderer's serial queue, matching ScreenCaptureKit's delivery contract.
    private struct SyntheticFrame: @unchecked Sendable {
        let sampleBuffer: CMSampleBuffer
    }

    @MainActor
    func testAddingAnAlreadyReadySourceSynchronizesVideoAndMaskImmediately() async throws {
        let ready = try await makeReadyRenderer()
        defer { ready.renderer.deactivate(token: ready.token) }
        let (window, composite) = makeComposite()
        defer { window.contentView = nil }

        // Registration delivers the renderer's accepted geometry while this
        // new wrapper still has zero bounds. No resize/layout pass follows.
        composite.update(entries: [entry(renderer: ready.renderer)])

        let (wrapper, video) = try sourceViews(in: composite)
        XCTAssertEqual(wrapper.frame, CGRect(x: 0, y: 0, width: 800, height: 450))
        XCTAssertFalse(wrapper.isHidden)
        assertPresentation(video, renderer: ready.renderer,
                           frame: CGRect(x: -50, y: -45, width: 900, height: 540),
                           mask: CGRect(x: 90, y: 45, width: 720, height: 450))
    }

    @MainActor
    func testShowingReadyLayerUsesItsLatestPlacementWithoutResizingCanvas() async throws {
        let ready = try await makeReadyRenderer()
        defer { ready.renderer.deactivate(token: ready.token) }
        let (window, composite) = makeComposite()
        defer { window.contentView = nil }
        let initial = NormalizedStageRect(x: 0.125, y: 0.1, width: 0.5, height: 0.5)
        let moved = NormalizedStageRect(x: 0.375, y: 0.2, width: 0.5, height: 0.5)

        composite.update(entries: [entry(renderer: ready.renderer, frame: initial, visible: false)])
        let (wrapper, video) = try sourceViews(in: composite)
        XCTAssertTrue(wrapper.isHidden)

        composite.update(entries: [entry(renderer: ready.renderer, frame: moved, visible: false)])
        composite.update(entries: [entry(renderer: ready.renderer, frame: moved, visible: true)])

        XCTAssertTrue(composite.subviews.first === wrapper)
        XCTAssertEqual(composite.bounds.size, CGSize(width: 800, height: 450))
        XCTAssertEqual(wrapper.frame, CGRect(x: 300, y: 90, width: 400, height: 225))
        XCTAssertFalse(wrapper.isHidden)
        assertPresentation(video, renderer: ready.renderer,
                           frame: CGRect(x: -25, y: -22.5, width: 450, height: 270),
                           mask: CGRect(x: 45, y: 22.5, width: 360, height: 225))
    }

    @MainActor
    func testChangingCropSynchronizesVideoAndAsymmetricMaskWithoutNewFrame() async throws {
        let ready = try await makeReadyRenderer()
        defer { ready.renderer.deactivate(token: ready.token) }
        let (window, composite) = makeComposite()
        defer { window.contentView = nil }
        composite.update(entries: [entry(renderer: ready.renderer)])
        let (wrapper, video) = try sourceViews(in: composite)

        // Keep the accepted frame and every outer size unchanged. The crop's
        // unequal top/bottom margins also exercise the mask's single Y flip.
        let crop = NormalizedSourceRect(x: 0.25, y: 0.1, width: 0.5, height: 0.6)
        composite.update(entries: [entry(renderer: ready.renderer, crop: crop)])

        XCTAssertEqual(composite.bounds.size, CGSize(width: 800, height: 450))
        XCTAssertEqual(wrapper.frame, composite.bounds)
        assertPresentation(video, renderer: ready.renderer,
                           frame: CGRect(x: -350, y: -150, width: 1_500, height: 900),
                           mask: CGRect(x: 450, y: 300, width: 600, height: 450))
    }

    @MainActor
    private func makeReadyRenderer() async throws -> (renderer: SampleBufferRenderer, token: UUID) {
        let queue = DispatchQueue(label: "test.composite.presentation")
        let renderer = SampleBufferRenderer(renderQueue: queue)
        let token = UUID()
        let generation = UUID()
        let frame = SyntheticFrame(sampleBuffer: try makeSyntheticFrame())
        let geometryReady = expectation(description: "Synthetic frame geometry is published")
        let observer = renderer.addPresentationGeometryObserver { update in
            if update.geometry != nil { geometryReady.fulfill() }
        }
        defer { renderer.removePresentationGeometryObserver(observer) }
        renderer.activate(token: token, showsCursor: false, presentationGeneration: generation)
        queue.async {
            renderer.enqueue(frame.sampleBuffer, token: token, presentationGeneration: generation)
        }
        await fulfillment(of: [geometryReady], timeout: 3)
        let geometry = try XCTUnwrap(renderer.presentationGeometry())
        XCTAssertEqual(geometry.surfaceSize, CGSize(width: 500, height: 300))
        XCTAssertEqual(geometry.contentRect, CGRect(x: 50, y: 25, width: 400, height: 250))
        return (renderer, token)
    }

    private func makeSyntheticFrame() throws -> CMSampleBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [kCVPixelBufferIOSurfacePropertiesKey: [:]]
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 1_000, 600,
                                         kCVPixelFormatType_32BGRA, attributes as CFDictionary,
                                         &pixelBuffer), kCVReturnSuccess)
        let pixels = try XCTUnwrap(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixels, [])
        if let bytes = CVPixelBufferGetBaseAddress(pixels) {
            memset(bytes, 0, CVPixelBufferGetBytesPerRow(pixels) * CVPixelBufferGetHeight(pixels))
        }
        CVPixelBufferUnlockBaseAddress(pixels, [])

        var format: CMVideoFormatDescription?
        XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixels, formatDescriptionOut: &format
        ), noErr)
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero,
                                        decodeTimeStamp: .invalid)
        var sampleBuffer: CMSampleBuffer?
        XCTAssertEqual(CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixels,
            formatDescription: try XCTUnwrap(format), sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        ), noErr)
        let sample = try XCTUnwrap(sampleBuffer)
        let array = try XCTUnwrap(CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true))
        let attachments = unsafeBitCast(CFArrayGetValueAtIndex(array, 0), to: NSMutableDictionary.self)
        attachments[SCStreamFrameInfo.status.rawValue] = SCFrameStatus.complete.rawValue
        attachments[SCStreamFrameInfo.contentRect.rawValue] =
            CGRect(x: 50, y: 25, width: 400, height: 250).dictionaryRepresentation
        attachments[SCStreamFrameInfo.scaleFactor.rawValue] = CGFloat(2)
        attachments[kCMSampleAttachmentKey_DisplayImmediately] = true
        return sample
    }

    @MainActor
    private func makeComposite() -> (NSWindow, StageCompositeNSView) {
        _ = NSApplication.shared
        let composite = StageCompositeNSView(frame: CGRect(x: 0, y: 0, width: 800, height: 450))
        let window = NSWindow(contentRect: composite.bounds, styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        // Attaching to an unshown window gives the video layer its real host
        // without opening UI, starting capture, or requesting a permission.
        window.contentView = composite
        return (window, composite)
    }

    private func entry(renderer: SampleBufferRenderer,
                       frame: NormalizedStageRect = .fullCanvas,
                       crop: NormalizedSourceRect = .fullSource,
                       visible: Bool = true) -> StageCompositeEntry {
        StageCompositeEntry(id: StageSourceID(rawValue: "synthetic-source"),
                            frame: frame, sourceCrop: crop, isVisible: visible,
                            renderer: renderer)
    }

    @MainActor
    private func sourceViews(in composite: StageCompositeNSView) throws
        -> (CroppedSampleBufferNSView, SampleBufferNSView) {
        let wrapper = try XCTUnwrap(composite.subviews.first as? CroppedSampleBufferNSView)
        let video = try XCTUnwrap(wrapper.subviews.first as? SampleBufferNSView)
        return (wrapper, video)
    }

    @MainActor
    private func assertPresentation(_ video: SampleBufferNSView, renderer: SampleBufferRenderer,
                                    frame: CGRect, mask: CGRect,
                                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(video.isHidden, file: file, line: line)
        XCTAssertTrue(renderer.displayLayer.superlayer === video.layer, file: file, line: line)
        assertRect(video.frame, equals: frame, file: file, line: line)
        assertRect(renderer.displayLayer.frame, equals: video.bounds, file: file, line: line)
        guard let actualMask = video.layer?.mask else {
            return XCTFail("The accepted source must have a visible-surface mask", file: file, line: line)
        }
        assertRect(actualMask.frame, equals: mask, file: file, line: line)
    }

    private func assertRect(_ actual: CGRect, equals expected: CGRect,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.minX, expected.minX, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(actual.minY, expected.minY, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(actual.width, expected.width, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: 0.000_001, file: file, line: line)
    }
}
