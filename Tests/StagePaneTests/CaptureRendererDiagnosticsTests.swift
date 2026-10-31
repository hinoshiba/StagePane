import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit
import StagePaneCore
import XCTest
@testable import StagePane

final class CaptureRendererDiagnosticsTests: XCTestCase {
    /// ScreenCaptureKit's delivery contract: the synthetic sample is immutable
    /// after it crosses to the renderer's serial queue.
    private struct Frame: @unchecked Sendable {
        let sampleBuffer: CMSampleBuffer
    }

    private final class WeakRenderer {
        weak var value: SampleBufferRenderer?
    }

    private final class Harness: @unchecked Sendable {
        let queue = DispatchQueue(label: "test.capture.renderer.diagnostics")
        let token = UUID()
        let generation = UUID()
        let renderer: SampleBufferRenderer

        init() {
            renderer = SampleBufferRenderer(renderQueue: queue)
        }

        func onQueue(_ operation: @escaping @Sendable () -> Void) async {
            await withCheckedContinuation { continuation in
                queue.async {
                    operation()
                    continuation.resume()
                }
            }
        }

        func progress() async -> CaptureRendererProgressSnapshot {
            await withCheckedContinuation { continuation in
                queue.async { [self] in
                    continuation.resume(returning: renderer.progressSnapshotOnRenderQueue())
                }
            }
        }
    }

    @MainActor
    func testQuietMonitorPreservesStaticImageGeometryAndLaserWithoutRecovery() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        let frame = try makeFrame(status: .complete)
        harness.renderer.setPointerStyle(.redDot)
        harness.renderer.activate(token: harness.token, showsCursor: false,
                                  presentationGeneration: harness.generation)
        try await accept(frame, in: harness, generation: harness.generation)

        let view = CroppedSampleBufferNSView(renderer: harness.renderer)
        view.update(frame: CGRect(x: 0, y: 0, width: 400, height: 200),
                    sourceCrop: .fullSource)
        let geometry = try XCTUnwrap(harness.renderer.presentationGeometry())
        let image = try XCTUnwrap(view.makeBitmapSnapshotImage())
        let pointer = try XCTUnwrap(harness.renderer.pointerOverlaySnapshot(at: CGPoint(x: 20, y: 20)))
        XCTAssertTrue(harness.renderer.shouldSamplePointerLocation())

        // The production monitor first fires after ten seconds, with one
        // second of permitted timer leeway. A legitimately static source may
        // send neither complete nor idle callbacks throughout this interval.
        try await Task.sleep(for: .seconds(12))
        let progress = await harness.progress()

        XCTAssertEqual(progress.completeFrames, 1)
        XCTAssertEqual(progress.idleFrames, 0)
        XCTAssertEqual(progress.enqueuedFrames, 1)
        XCTAssertEqual(progress.recoveryFlushes, 0,
                       "Quiet input is diagnostic information, not permission to reset rendering")
        XCTAssertFalse(progress.hasPendingFrame)
        XCTAssertFalse(progress.isRecovering)
        XCTAssertFalse(progress.isFlushingPresentation)
        XCTAssertEqual(harness.renderer.presentationGeometry(), geometry)
        XCTAssertTrue(harness.renderer.shouldSamplePointerLocation())
        let retainedPointer = try XCTUnwrap(harness.renderer.pointerOverlaySnapshot(at: CGPoint(x: 20, y: 20)))
        XCTAssertEqual(retainedPointer.normalizedPosition, pointer.normalizedPosition)
        XCTAssertEqual(retainedPointer.surfaceSize, pointer.surfaceSize)
        let retainedImage = try XCTUnwrap(view.makeBitmapSnapshotImage())
        XCTAssertEqual(retainedImage.width, image.width)
        XCTAssertEqual(retainedImage.height, image.height)
        XCTAssertEqual(retainedImage.dataProvider?.data as Data?, image.dataProvider?.data as Data?)
    }

    @MainActor
    func testGenerationBoundaryRejectsStaleCallbacksWithoutChangingCurrentProgress() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        let complete = try makeFrame(status: .complete)
        let idle = try makeFrame(status: .idle)
        harness.renderer.activate(token: harness.token, showsCursor: false,
                                  presentationGeneration: harness.generation)
        try await accept(complete, in: harness, generation: harness.generation)

        let nextGeneration = UUID()
        await harness.onQueue {
            harness.renderer.invalidatePresentationOnRenderQueue(
                token: harness.token,
                presentationGeneration: nextGeneration
            ) {
                harness.renderer.finishPresentationInvalidationOnRenderQueue(
                    token: harness.token,
                    presentationGeneration: nextGeneration
                )
            }
        }
        XCTAssertNil(harness.renderer.presentationGeometry())
        try await accept(complete, in: harness, generation: nextGeneration)
        await harness.onQueue {
            harness.renderer.enqueue(idle.sampleBuffer, token: harness.token,
                                     presentationGeneration: nextGeneration)
        }
        let acceptedGeometry = try XCTUnwrap(harness.renderer.presentationGeometry())

        await harness.onQueue {
            harness.renderer.enqueue(complete.sampleBuffer, token: harness.token,
                                     presentationGeneration: harness.generation)
            harness.renderer.enqueue(idle.sampleBuffer, token: UUID(),
                                     presentationGeneration: nextGeneration)
            harness.renderer.invalidatePresentationOnRenderQueue(
                token: UUID(), presentationGeneration: UUID(), completion: {}
            )
            harness.renderer.advanceEmptyPresentationGenerationOnRenderQueue(
                token: UUID(), presentationGeneration: UUID()
            )
        }
        let progress = await harness.progress()
        XCTAssertEqual(progress.completeFrames, 1)
        XCTAssertEqual(progress.idleFrames, 1)
        XCTAssertEqual(progress.enqueuedFrames, 1)
        XCTAssertEqual(progress.recoveryFlushes, 0)
        XCTAssertFalse(progress.hasPendingFrame)
        XCTAssertFalse(progress.isRecovering)
        XCTAssertFalse(progress.isFlushingPresentation)
        XCTAssertEqual(harness.renderer.presentationGeometry(), acceptedGeometry,
                       "Obsolete callbacks must neither refill nor clear the current presentation")
    }

    @MainActor
    func testProgressTimerDoesNotRetainADeactivatedRenderer() async throws {
        let queue = DispatchQueue(label: "test.capture.renderer.diagnostics.lifetime")
        let token = UUID()
        let generation = UUID()
        let frame = try makeFrame(status: .idle)
        var renderer: SampleBufferRenderer? = SampleBufferRenderer(renderQueue: queue)
        let releasedRenderer = WeakRenderer()
        releasedRenderer.value = renderer
        renderer?.activate(token: token, showsCursor: false, presentationGeneration: generation)
        // An idle callback arms the actual production timer without requiring
        // any AppKit view or geometry observer to own the renderer.
        await withCheckedContinuation { continuation in
            let activeRenderer = renderer!
            queue.async {
                activeRenderer.enqueue(frame.sampleBuffer, token: token,
                                       presentationGeneration: generation)
                continuation.resume()
            }
        }
        await withCheckedContinuation { continuation in
            renderer?.deactivate(token: token) { continuation.resume() }
        }
        renderer = nil
        // Let already queued MainActor suppression notifications finish. This
        // must not require waiting for the next ten-second timer deadline.
        for _ in 0..<20 where releasedRenderer.value != nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertNil(releasedRenderer.value)
    }

    @MainActor
    private func accept(_ frame: Frame, in harness: Harness, generation: UUID) async throws {
        let accepted = expectation(description: "Synthetic frame geometry is published")
        var observed = false
        let observer = harness.renderer.addPresentationGeometryObserver { update in
            if update.geometry != nil, !observed {
                observed = true
                accepted.fulfill()
            }
        }
        defer { harness.renderer.removePresentationGeometryObserver(observer) }
        await harness.onQueue {
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: generation)
        }
        await fulfillment(of: [accepted], timeout: 3)
        await harness.onQueue {}
        XCTAssertNotNil(harness.renderer.presentationGeometry())
    }

    private func makeFrame(status: SCFrameStatus) throws -> Frame {
        let width = 200
        let height = 100
        var pixelBuffer: CVPixelBuffer?
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer), kCVReturnSuccess)
        let pixels = try XCTUnwrap(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixels, [])
        if let base = CVPixelBufferGetBaseAddress(pixels) {
            memset(base, 64, CVPixelBufferGetBytesPerRow(pixels) * height)
        }
        CVPixelBufferUnlockBaseAddress(pixels, [])
        var format: CMVideoFormatDescription?
        XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixels, formatDescriptionOut: &format), noErr)
        var timing = CMSampleTimingInfo(duration: .invalid,
                                       presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                       decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        XCTAssertEqual(CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixels,
            formatDescription: try XCTUnwrap(format), sampleTiming: &timing,
            sampleBufferOut: &sample), noErr)
        let buffer = try XCTUnwrap(sample)
        let array = try XCTUnwrap(CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true))
        let attachments = unsafeBitCast(CFArrayGetValueAtIndex(array, 0), to: NSMutableDictionary.self)
        let rect = CGRect(x: 0, y: 0, width: width, height: height).dictionaryRepresentation
        attachments[SCStreamFrameInfo.status.rawValue] = status.rawValue
        attachments[SCStreamFrameInfo.contentRect.rawValue] = rect
        attachments[SCStreamFrameInfo.screenRect.rawValue] = rect
        attachments[SCStreamFrameInfo.contentScale.rawValue] = CGFloat(1)
        attachments[SCStreamFrameInfo.scaleFactor.rawValue] = CGFloat(1)
        return Frame(sampleBuffer: buffer)
    }
}
