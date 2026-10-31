import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit
import StagePaneCore
import XCTest
@testable import StagePane

final class StageSnapshotAuthorizationTests: XCTestCase {
    private struct Frame: @unchecked Sendable {
        let sampleBuffer: CMSampleBuffer
    }

    private final class Harness: @unchecked Sendable {
        let queue = DispatchQueue(label: "test.snapshot.authorization")
        let renderer: SampleBufferRenderer
        let token = UUID()
        let generation = UUID()

        init() {
            renderer = SampleBufferRenderer(renderQueue: queue)
            renderer.activate(token: token, showsCursor: false,
                              presentationGeneration: generation)
        }

        func onQueue(_ operation: @escaping @Sendable () -> Void) async {
            await withCheckedContinuation { continuation in
                queue.async {
                    operation()
                    continuation.resume()
                }
            }
        }
    }

    /// Injects a render-queue boundary after all source images are converted,
    /// at the point AppKit begins assembling them into the export bitmap.
    private final class SnapshotRootView: NSView {
        var beforeCaching: (() -> Void)?

        override func cacheDisplay(in rect: NSRect, to bitmapImageRep: NSBitmapImageRep) {
            beforeCaching?()
            super.cacheDisplay(in: rect, to: bitmapImageRep)
        }
    }

    @MainActor
    func testRevocationDuringSourceConversionRejectsTheImage() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        try await accept(makeFrame(value: 64), in: harness)
        XCTAssertNotNil(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))

        let snapshot = harness.renderer.makeBitmapSnapshot { _ in
            // This callback is after the renderer copies its accepted pixels
            // and geometry, but before Core Image converts those pixels.
            harness.renderer.revokeSnapshotAcceptance(token: harness.token)
        }

        XCTAssertNil(snapshot)
        XCTAssertNil(harness.renderer.presentationGeometry())
    }

    @MainActor
    func testOrdinaryNewFrameDoesNotRevokeAnAuthorizedImage() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        try await accept(makeFrame(value: 64), in: harness)
        let original = try XCTUnwrap(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))
        let newerFrame = try makeFrame(value: 192)

        let concurrentSnapshot = try XCTUnwrap(harness.renderer.makeBitmapSnapshot { _ in
            harness.queue.sync {
                harness.renderer.enqueue(newerFrame.sampleBuffer, token: harness.token,
                                         presentationGeneration: harness.generation)
            }
        })

        XCTAssertTrue(original.isStillAuthorized)
        XCTAssertTrue(concurrentSnapshot.isStillAuthorized)
        XCTAssertEqual(concurrentSnapshot.image.dataProvider?.data as Data?,
                       original.image.dataProvider?.data as Data?,
                       "An explicit snapshot remains coherent while ordinary video advances")
        let latest = try XCTUnwrap(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))
        XCTAssertNotEqual(latest.image.dataProvider?.data as Data?, original.image.dataProvider?.data as Data?)
    }

    @MainActor
    func testFinalExportRejectsAnEarlierSourceRevokedDuringComposition() async throws {
        let first = Harness()
        let second = Harness()
        defer {
            first.renderer.deactivate(token: first.token)
            second.renderer.deactivate(token: second.token)
        }
        try await accept(makeFrame(value: 64), in: first)
        try await accept(makeFrame(value: 192), in: second)
        let (window, root) = makeCanvas(renderers: [first.renderer, second.renderer])
        defer { window.contentView = nil }
        var didRevoke = false
        root.beforeCaching = {
            first.queue.sync {
                first.renderer.invalidatePresentationOnRenderQueue(
                    token: first.token, presentationGeneration: UUID(), completion: {}
                )
            }
            didRevoke = true
        }

        XCTAssertThrowsError(try StageWindowSnapshotter.capture(contentView: root)) { error in
            XCTAssertEqual(error as? StageWindowSnapshotError, .sourceFrameUnavailable(index: 0))
        }
        XCTAssertTrue(didRevoke, "The source must be revoked after conversion, during assembly")
        XCTAssertFalse(first.renderer.displayLayer.isHidden)
        XCTAssertFalse(second.renderer.displayLayer.isHidden)
    }

    @MainActor
    func testReturnedPNGRemainsAnExplicitSnapshotAfterLaterRevocation() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        try await accept(makeFrame(value: 64), in: harness)
        let (window, root) = makeCanvas(renderers: [harness.renderer])
        defer { window.contentView = nil }
        let snapshot = try StageWindowSnapshotter.capture(contentView: root)

        harness.renderer.revokeSnapshotAcceptance(token: harness.token)

        let decoded = try XCTUnwrap(NSBitmapImageRep(data: snapshot.pngData))
        XCTAssertEqual(decoded.pixelsWide, snapshot.pixelWidth)
        XCTAssertEqual(decoded.pixelsHigh, snapshot.pixelHeight)
        XCTAssertNil(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))
    }

    @MainActor
    func testRevocationFencesQueuedShowAcknowledgementAndLateFrames() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        let frame = try makeFrame(value: 64)
        let revoked = expectation(description: "Revoke before the initial show acknowledgement")
        var didRevoke = false
        let observer = harness.renderer.addPresentationGeometryObserver { update in
            if update.geometry != nil, !didRevoke {
                didRevoke = true
                harness.renderer.revokeSnapshotAcceptance(token: harness.token)
                revoked.fulfill()
            }
        }
        defer { harness.renderer.removePresentationGeometryObserver(observer) }
        await harness.onQueue {
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: harness.generation)
        }
        await fulfillment(of: [revoked], timeout: 3)
        await harness.onQueue {
            // The stream can still deliver samples while asynchronous Stop is
            // in flight. They must not reopen synchronous snapshot acceptance.
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: harness.generation)
        }
        await Task.yield()
        await harness.onQueue {}
        XCTAssertNil(harness.renderer.presentationGeometry())
        XCTAssertNil(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))
    }

    @MainActor
    func testQueuedGenerationChangesCannotReauthorizeRevokedSnapshots() async throws {
        let harness = Harness()
        defer { harness.renderer.deactivate(token: harness.token) }
        let frame = try makeFrame(value: 64)
        try await accept(frame, in: harness)
        let oldSnapshot = try XCTUnwrap(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))
        harness.renderer.revokeSnapshotAcceptance(token: harness.token)
        let resumeGeneration = UUID()
        let replacementGeneration = UUID()
        let invalidationFinished = expectation(description: "Presentation invalidation flush completed")

        await harness.onQueue {
            harness.renderer.advanceEmptyPresentationGenerationOnRenderQueue(
                token: harness.token, presentationGeneration: resumeGeneration
            )
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: resumeGeneration)
            harness.renderer.invalidatePresentationOnRenderQueue(
                token: harness.token, presentationGeneration: replacementGeneration
            ) {
                harness.renderer.finishPresentationInvalidationOnRenderQueue(
                    token: harness.token, presentationGeneration: replacementGeneration
                )
                invalidationFinished.fulfill()
            }
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: replacementGeneration)
        }
        await fulfillment(of: [invalidationFinished], timeout: 3)
        await harness.onQueue {
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: replacementGeneration)
        }
        // Wait for the actual pending-frame path to drain, including the
        // MainActor hide acknowledgement. No AVF-duration assumption is needed.
        let drainDeadline = ContinuousClock.now.advanced(by: .seconds(3))
        var hasPendingFrame = true
        while hasPendingFrame, ContinuousClock.now < drainDeadline {
            await Task.yield()
            hasPendingFrame = await withCheckedContinuation { continuation in
                harness.queue.async {
                    continuation.resume(returning:
                        harness.renderer.progressSnapshotOnRenderQueue().hasPendingFrame)
                }
            }
        }
        XCTAssertFalse(hasPendingFrame, "The late complete frame must finish its presentation path")
        await harness.onQueue {}
        XCTAssertFalse(oldSnapshot.isStillAuthorized)
        XCTAssertNil(harness.renderer.presentationGeometry())
        XCTAssertNil(harness.renderer.makeBitmapSnapshot(synchronizeGeometry: { _ in }))
    }

    @MainActor
    private func accept(_ frame: Frame, in harness: Harness) async throws {
        let accepted = expectation(description: "Synthetic geometry accepted")
        var didAccept = false
        let observer = harness.renderer.addPresentationGeometryObserver { update in
            if update.geometry != nil, !didAccept {
                didAccept = true
                accepted.fulfill()
            }
        }
        defer { harness.renderer.removePresentationGeometryObserver(observer) }
        await harness.onQueue {
            harness.renderer.enqueue(frame.sampleBuffer, token: harness.token,
                                     presentationGeneration: harness.generation)
        }
        await fulfillment(of: [accepted], timeout: 3)
        await harness.onQueue {}
    }

    @MainActor
    private func makeCanvas(renderers: [SampleBufferRenderer]) -> (NSWindow, SnapshotRootView) {
        _ = NSApplication.shared
        let root = SnapshotRootView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
        let composite = StageCompositeNSView(frame: root.bounds)
        root.addSubview(composite)
        let window = NSWindow(contentRect: root.bounds, styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = root
        let width = 1 / Double(renderers.count)
        composite.update(entries: renderers.enumerated().map { index, renderer in
            StageCompositeEntry(
                id: StageSourceID(rawValue: "synthetic-\(index)"),
                frame: NormalizedStageRect(x: Double(index) * width, y: 0, width: width, height: 1),
                sourceCrop: .fullSource,
                isVisible: true,
                renderer: renderer
            )
        })
        return (window, root)
    }

    private func makeFrame(value: Int32) throws -> Frame {
        var pixels: CVPixelBuffer?
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 200, 100,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixels), kCVReturnSuccess)
        let pixelBuffer = try XCTUnwrap(pixels)
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let base = CVPixelBufferGetBaseAddress(pixelBuffer) {
            memset(base, value, CVPixelBufferGetBytesPerRow(pixelBuffer) * 100)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        var format: CMVideoFormatDescription?
        XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &format), noErr)
        var timing = CMSampleTimingInfo(duration: .invalid,
                                       presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                       decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        XCTAssertEqual(CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
            formatDescription: try XCTUnwrap(format), sampleTiming: &timing,
            sampleBufferOut: &sample), noErr)
        let buffer = try XCTUnwrap(sample)
        let array = try XCTUnwrap(CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true))
        let attachments = unsafeBitCast(CFArrayGetValueAtIndex(array, 0), to: NSMutableDictionary.self)
        attachments[SCStreamFrameInfo.status.rawValue] = SCFrameStatus.complete.rawValue
        attachments[SCStreamFrameInfo.contentRect.rawValue] =
            CGRect(x: 0, y: 0, width: 200, height: 100).dictionaryRepresentation
        attachments[SCStreamFrameInfo.contentScale.rawValue] = CGFloat(1)
        attachments[SCStreamFrameInfo.scaleFactor.rawValue] = CGFloat(1)
        return Frame(sampleBuffer: buffer)
    }
}
