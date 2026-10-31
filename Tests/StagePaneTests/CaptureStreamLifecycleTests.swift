import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit
import StagePaneCore
import XCTest
@testable import StagePane

final class CaptureStreamLifecycleTests: XCTestCase {
    private struct GeometryEvent {
        let contentGeneration: Int
        let presentationGeneration: UUID
        let geometry: CaptureSourceGeometry
    }

    private final class EventLog: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [GeometryEvent] = []

        func append(_ value: GeometryEvent) {
            lock.lock()
            values.append(value)
            lock.unlock()
        }

        var geometry: [GeometryEvent] {
            lock.lock()
            defer { lock.unlock() }
            return values
        }
    }

    /// The real proxy/renderers receive immutable synthetic frames. This stream
    /// is only an identity argument to the output callback: capture is never
    /// started, and no source enumeration or permission request is performed.
    private final class Harness: @unchecked Sendable {
        let queue = DispatchQueue(label: "test.capture.lifecycle")
        let token = UUID()
        let generation = UUID()
        let events = EventLog()
        let renderers: CaptureSourceRenderers
        let proxy: CaptureStreamProxy
        let stream: SCStream

        init() {
            renderers = CaptureSourceRenderers(renderQueue: queue)
            let events = events
            proxy = CaptureStreamProxy(
                token: token,
                renderers: renderers,
                outputQueue: queue,
                initialPresentationGeneration: generation,
                geometryHandler: { _, contentGeneration, presentationGeneration, geometry in
                    events.append(GeometryEvent(
                        contentGeneration: contentGeneration,
                        presentationGeneration: presentationGeneration,
                        geometry: geometry
                    ))
                },
                presentationHandler: { _, _ in },
                stopHandler: { _, _, _ in }
            )
            stream = SCStream(
                filter: SCContentFilter(),
                configuration: SCStreamConfiguration(),
                delegate: nil
            )
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

    private struct Frame: @unchecked Sendable {
        let sampleBuffer: CMSampleBuffer
    }

    func testResumeReleasesEarlyGeometryWithoutAnotherFrame() async throws {
        let harness = Harness()
        let frame = try makeFrame(width: 200, height: 100)
        await harness.onQueue {
            harness.proxy.beginExplicitResumeOnOutputQueue(
                presentationGeneration: harness.generation
            )
            for _ in 0..<101 {
                harness.proxy.stream(harness.stream, didOutputSampleBuffer: frame.sampleBuffer, of: .screen)
            }
        }
        XCTAssertTrue(harness.events.geometry.isEmpty,
                      "Geometry must wait until the coordinator has completed Resume")

        await harness.onQueue {
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: harness.generation)
        }
        let delivered = try XCTUnwrap(harness.events.geometry.first)
        XCTAssertEqual(delivered.geometry.pointWidth, 200)
        XCTAssertEqual(delivered.geometry.pointHeight, 100)
        XCTAssertEqual(delivered.presentationGeneration, harness.generation)
        XCTAssertEqual(harness.events.geometry.count, 1)
    }

    func testReplacementReleasesLatestGeometryAfterCoordinatorCompletion() async throws {
        let harness = Harness()
        let first = try makeFrame(width: 200, height: 100)
        let latest = try makeFrame(width: 300, height: 100)
        await harness.onQueue {
            harness.proxy.beginContentReplacementOnOutputQueue(
                presentationGeneration: harness.generation
            )
            harness.proxy.finishContentReplacementOnOutputQueue(
                presentationGeneration: harness.generation,
                geometryGeneration: 7
            )
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: first.sampleBuffer, of: .screen)
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: latest.sampleBuffer, of: .screen)
        }
        XCTAssertTrue(harness.events.geometry.isEmpty)
        await harness.onQueue {
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: harness.generation)
        }
        let delivered = try XCTUnwrap(harness.events.geometry.first)
        XCTAssertEqual(delivered.contentGeneration, 7)
        XCTAssertEqual(delivered.geometry.pointWidth, 300)
        XCTAssertEqual(harness.events.geometry.count, 1)
    }

    func testFailedPauseReleasesEarlyGeometryAfterCoordinatorCompletion() async throws {
        let harness = Harness()
        let frame = try makeFrame(width: 200, height: 100)
        await harness.onQueue {
            harness.proxy.beginExplicitPauseOnOutputQueue(
                presentationGeneration: harness.generation
            )
            harness.proxy.cancelExplicitPauseOnOutputQueue()
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: frame.sampleBuffer, of: .screen)
        }
        XCTAssertTrue(harness.events.geometry.isEmpty,
                      "A failed stop must wait until the coordinator clears its pausing state")
        await harness.onQueue {
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: harness.generation)
        }
        XCTAssertEqual(harness.events.geometry.count, 1)
        XCTAssertEqual(harness.events.geometry.first?.geometry.pointWidth, 200)
    }

    func testResumeReleasesGeometryFromLatestAvailablePresentation() async throws {
        let harness = Harness()
        let first = try makeFrame(width: 200, height: 100)
        let unavailable = try makeFrame(width: 200, height: 100, status: .blank)
        let returned = try makeFrame(width: 300, height: 100)
        await harness.onQueue {
            harness.proxy.beginExplicitResumeOnOutputQueue(
                presentationGeneration: harness.generation
            )
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: first.sampleBuffer, of: .screen)
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: unavailable.sampleBuffer, of: .screen)
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: returned.sampleBuffer, of: .screen)
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: harness.generation)
        }
        let delivered = try XCTUnwrap(harness.events.geometry.first)
        XCTAssertEqual(harness.events.geometry.count, 1)
        XCTAssertEqual(delivered.geometry.pointWidth, 300)
        XCTAssertNotEqual(delivered.presentationGeneration, harness.generation,
                          "A stable operation ID must release geometry from the latest presentation")
    }

    func testOlderCompletionCannotReleaseNewResumeGeometry() async throws {
        let harness = Harness()
        let newGeneration = UUID()
        let frame = try makeFrame(width: 200, height: 100)
        await harness.onQueue {
            harness.proxy.beginExplicitResumeOnOutputQueue(
                presentationGeneration: harness.generation
            )
            harness.proxy.cancelExplicitResumeOnOutputQueue()
            harness.proxy.beginExplicitResumeOnOutputQueue(
                presentationGeneration: newGeneration
            )
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: frame.sampleBuffer, of: .screen)
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: harness.generation)
        }
        XCTAssertTrue(harness.events.geometry.isEmpty)
        await harness.onQueue {
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: newGeneration)
        }
        XCTAssertEqual(harness.events.geometry.count, 1)
        XCTAssertEqual(harness.events.geometry.first?.presentationGeneration, newGeneration)
    }

    @MainActor
    func testFailedResumeClearsBothAcceptedFramesAndNextResumeSurvivesFlush() async throws {
        let harness = Harness()
        let frame = try makeFrame(width: 200, height: 100)
        let firstFrames = expectation(description: "Both renderers accept the early Resume frame")
        firstFrames.expectedFulfillmentCount = 2
        let replacementFrames = expectation(description: "Both renderers accept the retried Resume frame")
        replacementFrames.expectedFulfillmentCount = 2
        let observer: PresentationGeometryHandler = { update in
            if update.geometry?.surfaceSize.width == 200 { firstFrames.fulfill() }
            if update.geometry?.surfaceSize.width == 300 { replacementFrames.fulfill() }
        }
        let stageObserver = harness.renderers.stage.addPresentationGeometryObserver(observer)
        let previewObserver = harness.renderers.preview.addPresentationGeometryObserver(observer)
        defer {
            harness.renderers.stage.removePresentationGeometryObserver(stageObserver)
            harness.renderers.preview.removePresentationGeometryObserver(previewObserver)
            harness.renderers.deactivate(token: harness.token)
        }
        harness.renderers.activate(token: harness.token, showsCursor: true,
                                   presentationGeneration: harness.generation)
        await harness.onQueue {
            harness.proxy.beginExplicitResumeOnOutputQueue(
                presentationGeneration: harness.generation
            )
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: frame.sampleBuffer, of: .screen)
        }
        await fulfillment(of: [firstFrames], timeout: 3)
        XCTAssertNotNil(harness.renderers.stage.presentationGeometry())
        XCTAssertNotNil(harness.renderers.preview.presentationGeometry())

        await harness.onQueue {
            harness.proxy.cancelExplicitResumeOnOutputQueue()
            // Callbacks already in transit after failure cannot refill either surface.
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: frame.sampleBuffer, of: .screen)
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: harness.generation)
        }
        XCTAssertNil(harness.renderers.stage.presentationGeometry())
        XCTAssertNil(harness.renderers.preview.presentationGeometry())
        XCTAssertTrue(harness.events.geometry.isEmpty)

        let nextGeneration = UUID()
        let nextFrame = try makeFrame(width: 300, height: 100)
        await harness.onQueue {
            harness.proxy.beginExplicitResumeOnOutputQueue(presentationGeneration: nextGeneration)
            harness.proxy.stream(harness.stream, didOutputSampleBuffer: nextFrame.sampleBuffer, of: .screen)
            harness.proxy.finishGeometryDeliveryOnOutputQueue(operationID: nextGeneration)
        }
        await fulfillment(of: [replacementFrames], timeout: 3)
        await harness.onQueue {}
        XCTAssertEqual(harness.renderers.stage.presentationGeometry()?.surfaceSize.width, 300)
        XCTAssertEqual(harness.renderers.preview.presentationGeometry()?.surfaceSize.width, 300)
        XCTAssertEqual(harness.events.geometry.first?.presentationGeneration, nextGeneration)
    }

    private func makeFrame(
        width: Int,
        height: Int,
        status: SCFrameStatus = .complete
    ) throws -> Frame {
        var pixelBuffer: CVPixelBuffer?
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer), kCVReturnSuccess)
        let pixels = try XCTUnwrap(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixels, [])
        if let base = CVPixelBufferGetBaseAddress(pixels) {
            memset(base, 0, CVPixelBufferGetBytesPerRow(pixels) * height)
        }
        CVPixelBufferUnlockBaseAddress(pixels, [])
        var format: CMVideoFormatDescription?
        XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixels, formatDescriptionOut: &format), noErr)
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero,
                                       decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        XCTAssertEqual(CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixels,
            formatDescription: try XCTUnwrap(format), sampleTiming: &timing,
            sampleBufferOut: &sample), noErr)
        let buffer = try XCTUnwrap(sample)
        let array = try XCTUnwrap(CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true))
        let attachments = unsafeBitCast(CFArrayGetValueAtIndex(array, 0), to: NSMutableDictionary.self)
        attachments[SCStreamFrameInfo.status.rawValue] = status.rawValue
        attachments[SCStreamFrameInfo.contentRect.rawValue] =
            CGRect(x: 0, y: 0, width: width, height: height).dictionaryRepresentation
        attachments[SCStreamFrameInfo.contentScale.rawValue] = CGFloat(1)
        attachments[SCStreamFrameInfo.scaleFactor.rawValue] = CGFloat(1)
        attachments[kCMSampleAttachmentKey_DisplayImmediately] = true
        return Frame(sampleBuffer: buffer)
    }
}
