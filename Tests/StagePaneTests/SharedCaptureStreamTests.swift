import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit
import StagePaneCore
import XCTest
@testable import StagePane

final class SharedCaptureStreamTests: XCTestCase {
    @MainActor
    private final class Driver: SharedCaptureStreamDriver {
        let stream = SCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let output: SharedCaptureStreamOutput
        var starts = 0
        var stops = 0
        var removals = 0
        var updates: [CaptureStreamSettings] = []
        var startFailure: Error?
        var stopFailure: Error?
        var updateFailure: Error?
        var settings: CaptureStreamSettings

        init(settings: CaptureStreamSettings, output: SharedCaptureStreamOutput) {
            self.settings = settings
            self.output = output
        }
        func start() async throws {
            starts += 1
            if let startFailure { throw startFailure }
        }
        func stop() async throws {
            stops += 1
            if let stopFailure { throw stopFailure }
        }
        func update(_ settings: CaptureStreamSettings) async throws {
            if let updateFailure { throw updateFailure }
            self.settings = settings
            updates.append(settings)
        }
        func removeOutput() throws { removals += 1 }
        func emit(_ frame: Frame) {
            let output = output
            let streamBox = SendableBox(stream)
            output.queue.async {
                output.stream(streamBox.value, didOutputSampleBuffer: frame.sample, of: .screen)
            }
        }
    }

    @MainActor
    private final class Factory {
        var drivers: [Driver] = []
        func make(_ filter: SCContentFilter, _ settings: CaptureStreamSettings, _ output: SharedCaptureStreamOutput) -> any SharedCaptureStreamDriver {
            let driver = Driver(settings: settings, output: output)
            drivers.append(driver)
            return driver
        }
    }

    @MainActor
    private final class Consumer {
        let queue = DispatchQueue(label: "test.shared-input.consumer")
        let token = UUID()
        let generation = UUID()
        let renderers: CaptureSourceRenderers
        let proxy: CaptureStreamProxy
        let lease: CaptureStreamLease

        init(pool: SharedCaptureStreamPool, filter: SCContentFilter,
             width: Int = 64, height: Int = 32, showsCursor: Bool = false) throws {
            renderers = CaptureSourceRenderers(renderQueue: queue)
            proxy = CaptureStreamProxy(token: token, renderers: renderers, outputQueue: queue,
                initialPresentationGeneration: generation,
                geometryHandler: { _, _, _, _ in }, presentationHandler: { _, _ in }, stopHandler: { _, _, _ in })
            lease = try pool.acquire(filter: filter, configuration: CaptureStreamSettings(
                width: width, height: height, showsCursor: showsCursor).makeConfiguration(), proxy: proxy, queue: queue)
            renderers.activate(token: token, showsCursor: showsCursor, presentationGeneration: generation)
        }
        func close() async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lease.stopCapture { error in
                    if let error { continuation.resume(throwing: error) } else { continuation.resume() }
                }
            }
            try lease.removeStreamOutput()
            renderers.deactivate(token: token)
        }
    }

    private struct Frame: @unchecked Sendable { let sample: CMSampleBuffer }

    @MainActor
    func testTenConsumersUseOneNativeInputWithMaximumRequiredResolution() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        var consumers: [Consumer] = []
        for index in 1...10 {
            let consumer = try Consumer(pool: pool, filter: SCContentFilter(), width: index * 100, height: index * 50)
            consumers.append(consumer)
            try await start(consumer.lease)
        }
        XCTAssertEqual(pool.inputCount, 1)
        XCTAssertEqual(pool.runningInputCount, 1)
        XCTAssertEqual(factory.drivers.count, 1)
        let driver = try XCTUnwrap(factory.drivers.first)
        XCTAssertEqual(driver.starts, 1)
        XCTAssertEqual(driver.settings.width, 1000)
        XCTAssertEqual(driver.settings.height, 500)
        for consumer in consumers.dropLast() { try await consumer.close() }
        XCTAssertEqual(driver.stops, 0, "Removing other layers must leave the final subscriber running")
        try await consumers.last?.close()
        XCTAssertEqual(driver.stops, 1)
        XCTAssertEqual(driver.removals, 1)
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testSmallerLayoutAndCropDemandDoesNotReconfigureTheLargerInput() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let large = try Consumer(pool: pool, filter: SCContentFilter(), width: 1920, height: 1080)
        let small = try Consumer(pool: pool, filter: SCContentFilter(), width: 640, height: 360)
        try await start(large.lease)
        try await start(small.lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        let before = driver.updates.count
        try await configure(small.lease, width: 960, height: 540)
        XCTAssertEqual(driver.updates.count, before)
        XCTAssertEqual(driver.settings.width, 1920)
        try await configure(small.lease, width: 2560, height: 1440)
        XCTAssertEqual(driver.updates.count, before + 1)
        XCTAssertEqual(driver.settings.width, 2560)
        XCTAssertEqual(driver.starts, 1)
        try await large.close()
        try await small.close()
    }

    @MainActor
    func testStaticFrameIsReusedButCropAndColorRemainIndependent() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.emit(try makeFrame())
        await eventually { first.renderers.preview.presentationGeometry() != nil }
        let second = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(second.lease)
        // No second native callback: a static window still appears on a new tab.
        await eventually { second.renderers.preview.presentationGeometry() != nil }
        let left = CroppedSampleBufferNSView(renderer: first.renderers.preview)
        let right = CroppedSampleBufferNSView(renderer: second.renderers.preview)
        left.update(frame: CGRect(x: 0, y: 0, width: 64, height: 64),
                    sourceCrop: NormalizedSourceRect(x: 0, y: 0, width: 0.5, height: 1))
        right.update(frame: CGRect(x: 0, y: 0, width: 96, height: 96),
                     sourceCrop: NormalizedSourceRect(x: 0.5, y: 0, width: 0.5, height: 1))
        let leftImage = try XCTUnwrap(left.makeBitmapSnapshotImage())
        let rightImage = try XCTUnwrap(right.makeBitmapSnapshotImage())
        // Snapshot pixels are the shared full source; the wrapper positions
        // and clips them separately for each layer at composition time.
        XCTAssertEqual(leftImage.dataProvider?.data as Data?, rightImage.dataProvider?.data as Data?)
        XCTAssertEqual(left.subviews.first?.frame, CGRect(x: 0, y: 0, width: 128, height: 64))
        XCTAssertEqual(right.subviews.first?.frame, CGRect(x: -96, y: 0, width: 192, height: 96))
        let leftColor = try XCTUnwrap(NSBitmapImageRep(cgImage: leftImage).colorAt(x: 8, y: 8))
        let rightColor = try XCTUnwrap(NSBitmapImageRep(cgImage: rightImage).colorAt(x: 48, y: 8))
        XCTAssertGreaterThan(leftColor.greenComponent, 0.9)
        XCTAssertGreaterThan(rightColor.blueComponent, 0.9)
        second.renderers.setColorInverted(true)
        let inverted = try XCTUnwrap(right.makeBitmapSnapshotImage())
        XCTAssertNotEqual(inverted.dataProvider?.data as Data?, rightImage.dataProvider?.data as Data?)
        XCTAssertEqual(try XCTUnwrap(left.makeBitmapSnapshotImage()).dataProvider?.data as Data?, leftImage.dataProvider?.data as Data?)
        XCTAssertEqual(factory.drivers.count, 1)
        try await first.close()
        try await second.close()
    }

    @MainActor
    func testEndedInputRevokesEveryConsumersExportAndCannotBeReused() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        let second = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        try await start(second.lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.emit(try makeFrame())
        await eventually { first.renderers.preview.presentationGeometry() != nil && second.renderers.preview.presentationGeometry() != nil }
        let firstView = CroppedSampleBufferNSView(renderer: first.renderers.preview)
        let secondView = CroppedSampleBufferNSView(renderer: second.renderers.preview)
        firstView.update(frame: CGRect(x: 0, y: 0, width: 64, height: 32), sourceCrop: .fullSource)
        secondView.update(frame: CGRect(x: 0, y: 0, width: 64, height: 32), sourceCrop: .fullSource)
        XCTAssertNotNil(firstView.makeBitmapSnapshotImage())
        XCTAssertNotNil(secondView.makeBitmapSnapshotImage())
        driver.output.stream(driver.stream, didStopWithError: NSError(
            domain: SCStreamError.errorDomain, code: SCStreamError.Code.userStopped.rawValue))
        XCTAssertNil(firstView.makeBitmapSnapshotImage())
        XCTAssertNil(secondView.makeBitmapSnapshotImage())
        let replacement = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(replacement.lease)
        XCTAssertEqual(factory.drivers.count, 2, "Fresh consent must never revive a revoked stream")
        XCTAssertFalse(replacement.lease.nativeStream === first.lease.nativeStream)
        try await first.close()
        try await second.close()
        try await replacement.close()
    }

    @MainActor
    func testBlankInputDoesNotReplayOldPixelsToNewConsumer() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.emit(try makeFrame())
        await eventually { first.renderers.preview.presentationGeometry() != nil }
        driver.emit(try makeFrame(status: .blank))
        await eventually { first.renderers.preview.presentationGeometry() == nil }
        let second = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(second.lease)
        await drain(second.queue)
        XCTAssertNil(second.renderers.preview.presentationGeometry())
        driver.emit(try makeFrame())
        await eventually { first.renderers.preview.presentationGeometry() != nil && second.renderers.preview.presentationGeometry() != nil }
        try await first.close()
        try await second.close()
    }

    @MainActor
    func testReplacingOneConsumerLeavesOthersOnTheirOriginalInput() async throws {
        let factory = Factory()
        let original = SCContentFilter()
        let replacement = SCContentFilter()
        let originalID = ObjectIdentifier(original)
        let pool = SharedCaptureStreamPool(identify: {
            .window(id: ObjectIdentifier($0) == originalID ? 1 : 2, processID: 42)
        }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: original)
        let second = try Consumer(pool: pool, filter: original)
        try await start(first.lease)
        try await start(second.lease)
        let originalStream = first.lease.nativeStream
        try await replace(first.lease, with: replacement)
        XCTAssertFalse(first.lease.nativeStream === originalStream)
        XCTAssertTrue(second.lease.nativeStream === originalStream)
        XCTAssertEqual(factory.drivers[0].stops, 0)
        XCTAssertEqual(factory.drivers.count, 2)
        try await replace(first.lease, with: original)
        XCTAssertTrue(first.lease.nativeStream === second.lease.nativeStream)
        XCTAssertEqual(factory.drivers.count, 2, "Returning to an existing input must rejoin it")
        XCTAssertEqual(factory.drivers[1].stops, 1)
        XCTAssertEqual(pool.inputCount, 1)
        try await first.close()
        try await second.close()
    }

    @MainActor
    func testDifferentNativeCursorModesAreIsolatedAndRejoinWhenCompatible() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter(), showsCursor: true)
        let second = try Consumer(pool: pool, filter: SCContentFilter(), showsCursor: false)
        try await start(first.lease)
        try await start(second.lease)
        XCTAssertEqual(factory.drivers.count, 2)
        try await configure(first.lease, width: 64, height: 32, showsCursor: false)
        XCTAssertTrue(first.lease.nativeStream === second.lease.nativeStream)
        XCTAssertEqual(pool.inputCount, 1)
        XCTAssertEqual(factory.drivers[1].starts, 1)
        try await first.close()
        try await second.close()
    }

    @MainActor
    func testStopFailureRetainsInputForRetryInsteadOfDuplicatingIt() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.stopFailure = NSError(domain: "test", code: 1)
        do { try await stop(first.lease); XCTFail("Expected native stop failure") } catch {}
        XCTAssertEqual(pool.runningInputCount, 1)
        XCTAssertThrowsError(try first.lease.removeStreamOutput())
        let second = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(second.lease)
        XCTAssertEqual(factory.drivers.count, 1)
        XCTAssertEqual(driver.starts, 1)
        driver.stopFailure = nil
        try await first.close()
        try await second.close()
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testUnknownFilterIdentitiesAreNotMergedByTheirEqualSize() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(factory: factory.make)
        let firstFilter = SCContentFilter()
        let first = try Consumer(pool: pool, filter: firstFilter)
        let sameFilter = try Consumer(pool: pool, filter: firstFilter)
        let differentFilter = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        try await start(sameFilter.lease)
        try await start(differentFilter.lease)
        XCTAssertEqual(factory.drivers.count, 2)
        XCTAssertTrue(first.lease.nativeStream === sameFilter.lease.nativeStream)
        XCTAssertFalse(first.lease.nativeStream === differentFilter.lease.nativeStream)
        try await first.close()
        try await sameFilter.close()
        try await differentFilter.close()
    }

    @MainActor
    func testCoordinatorsShareInputButPauseResumeAndRemoveIndependently() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try await openCoordinator(pool: pool, filter: SCContentFilter())
        let second = try await openCoordinator(pool: pool, filter: SCContentFilter())
        let firstSource = try XCTUnwrap(first.sources.first)
        let secondSource = try XCTUnwrap(second.sources.first)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.emit(try makeFrame())
        await eventually { firstSource.isPresentationVisible && secondSource.isPresentationVisible }
        first.togglePause(firstSource.id)
        await eventually { firstSource.isPaused }
        XCTAssertFalse(firstSource.isPresentationVisible)
        XCTAssertTrue(secondSource.isPresentationVisible)
        XCTAssertEqual(driver.stops, 0)
        first.togglePause(firstSource.id)
        await eventually { !firstSource.isPaused && firstSource.isPresentationVisible }
        XCTAssertEqual(driver.starts, 1)
        await stopCoordinator(first)
        XCTAssertTrue(first.sources.isEmpty)
        XCTAssertTrue(secondSource.isPresentationVisible)
        XCTAssertEqual(driver.stops, 0)
        await stopCoordinator(second)
        XCTAssertEqual(driver.stops, 1)
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testSystemReplacementUpdatesAllConsumersInsideOneCoordinator() async throws {
        let factory = Factory()
        let original = SCContentFilter()
        let replacement = SCContentFilter()
        let originalID = ObjectIdentifier(original)
        let pool = SharedCaptureStreamPool(identify: {
            .window(id: ObjectIdentifier($0) == originalID ? 1 : 2, processID: 42)
        }, factory: factory.make)
        let capture = try await openCoordinator(pool: pool, filter: original)
        XCTAssertTrue(capture.beginPickerPresentation())
        capture.contentSharingPicker(.shared, didUpdateWith: original, for: nil)
        await eventually { capture.sources.count == 2 && capture.runningSourceCount == 2 }
        XCTAssertEqual(factory.drivers.count, 1)
        capture.contentSharingPicker(.shared, didUpdateWith: replacement, for: factory.drivers[0].stream)
        await eventually { factory.drivers.count == 2 && factory.drivers[0].removals == 1 }
        XCTAssertEqual(factory.drivers[1].starts, 1)
        await stopCoordinator(capture)
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testLastPauseClearsCachedFramesAndResumeWaitsForNewCapture() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let capture = try await openCoordinator(pool: pool, filter: SCContentFilter())
        let source = try XCTUnwrap(capture.sources.first)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.emit(try makeFrame())
        await eventually { source.isPresentationVisible }
        capture.togglePause(source.id)
        await eventually { source.isPaused }
        XCTAssertEqual(driver.stops, 1)
        // Even a late native callback after Stop must not become a cached
        // frame for the next subscription or resume.
        driver.emit(try makeFrame())
        await drain(driver.output.queue)
        capture.togglePause(source.id)
        await eventually { !source.isPaused }
        XCTAssertEqual(driver.starts, 2)
        XCTAssertFalse(source.isPresentationVisible)
        driver.emit(try makeFrame())
        await eventually { source.isPresentationVisible }
        await stopCoordinator(capture)
    }

    @MainActor
    func testQueuedFramesFromReplacedInputCannotReachNewBinding() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        let releaseQueue = DispatchSemaphore(value: 0)
        first.queue.async { releaseQueue.wait() }
        defer { releaseQueue.signal() }
        factory.drivers[0].emit(try makeFrame())
        await drain(factory.drivers[0].output.queue)
        try await replace(first.lease, with: SCContentFilter())
        releaseQueue.signal()
        await drain(first.queue)
        XCTAssertNil(first.renderers.preview.presentationGeometry())
        factory.drivers[1].emit(try makeFrame())
        await eventually { first.renderers.preview.presentationGeometry() != nil }
        try await first.close()
    }

    @MainActor
    func testFailedLargerConfigurationLeavesExistingSubscriberRunning() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(first.lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.updateFailure = NSError(domain: "test", code: 1)
        let second = try Consumer(pool: pool, filter: SCContentFilter(), width: 1920, height: 1080)
        do { try await start(second.lease); XCTFail("Expected configuration failure") } catch {}
        try await second.close()
        XCTAssertEqual(driver.stops, 0)
        XCTAssertEqual(driver.settings.width, 64)
        driver.emit(try makeFrame())
        await eventually { first.renderers.preview.presentationGeometry() != nil }
        try await first.close()
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testFailedStartAndStopKeepCleanupOwnedUntilRetry() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let first = try Consumer(pool: pool, filter: SCContentFilter())
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.startFailure = NSError(domain: "test", code: 1)
        driver.stopFailure = NSError(domain: "test", code: 2)
        do { try await start(first.lease); XCTFail("Expected start failure") } catch {}
        do { try await stop(first.lease); XCTFail("Expected stop failure") } catch {}
        XCTAssertTrue(first.lease.needsStopBeforeRelease)
        XCTAssertThrowsError(try first.lease.removeStreamOutput())
        let second = try Consumer(pool: pool, filter: SCContentFilter())
        do { try await start(second.lease); XCTFail("Unconfirmed start must not be reused as a running input") } catch {}
        XCTAssertEqual(factory.drivers.count, 1)
        XCTAssertEqual(driver.starts, 1)
        driver.stopFailure = NSError(domain: SCStreamError.errorDomain,
            code: SCStreamError.Code.attemptToStopStreamState.rawValue)
        try await first.close()
        try await second.close()
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testFailedResumeStillRequiresNativeStopBeforeLayerRemoval() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let capture = try await openCoordinator(pool: pool, filter: SCContentFilter())
        let source = try XCTUnwrap(capture.sources.first)
        let driver = try XCTUnwrap(factory.drivers.first)
        capture.togglePause(source.id)
        await eventually { source.isPaused }
        driver.startFailure = NSError(domain: "test", code: 1)
        driver.stopFailure = NSError(domain: "test", code: 2)
        capture.togglePause(source.id)
        await eventually { capture.attentionSummary(for: source.id) != nil }
        let error: String? = await withCheckedContinuation { continuation in
            capture.stop { continuation.resume(returning: $0) }
        }
        XCTAssertNotNil(error)
        XCTAssertEqual(capture.sources.count, 1)
        XCTAssertTrue(capture.isCaptureActive)
        XCTAssertEqual(pool.runningInputCount, 1)
        driver.stopFailure = nil
        await stopCoordinator(capture)
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testAbandonedLastActiveSubscriberStopsEvenWithPausedSubscriberRemaining() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        var active: Consumer? = try Consumer(pool: pool, filter: SCContentFilter())
        let paused = try Consumer(pool: pool, filter: SCContentFilter())
        try await start(try XCTUnwrap(active).lease)
        let driver = try XCTUnwrap(factory.drivers.first)
        driver.stopFailure = NSError(domain: "test", code: 1)
        active = nil
        await eventually { driver.stops == 1 }
        XCTAssertEqual(pool.runningInputCount, 1)
        driver.stopFailure = nil
        await eventually { pool.runningInputCount == 0 }
        XCTAssertEqual(driver.stops, 2)
        try await paused.close()
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testSystemPickerReplacementReachesEveryGroupSharingTheInput() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(factory: factory.make)
        let filter = SCContentFilter()
        let first = try await openCoordinator(pool: pool, filter: filter)
        let second = try await openCoordinator(pool: pool, filter: filter)
        let original = try XCTUnwrap(factory.drivers.first)
        CapturePickerRouter.shared.contentSharingPicker(.shared, didUpdateWith: SCContentFilter(), for: original.stream)
        await eventually { factory.drivers.count == 2 && original.removals == 1 }
        XCTAssertEqual(factory.drivers[1].starts, 1)
        XCTAssertEqual(first.sources.count, 1)
        XCTAssertEqual(second.sources.count, 1)
        await stopCoordinator(first)
        XCTAssertEqual(factory.drivers[1].stops, 0)
        await stopCoordinator(second)
        XCTAssertEqual(pool.inputCount, 0)
    }

    @MainActor
    func testJoiningStaticCursorlessInputEnablesLaserAfterConfigurationCommits() async throws {
        let factory = Factory()
        let pool = SharedCaptureStreamPool(identify: { _ in .window(id: 7, processID: 42) }, factory: factory.make)
        let system = try await openCoordinator(pool: pool, filter: SCContentFilter())
        let cursorless = CaptureCoordinator(acceptsNewSources: true, streamPool: pool)
        cursorless.setPointerStyle(.hidden)
        XCTAssertTrue(cursorless.beginPickerPresentation())
        cursorless.contentSharingPicker(.shared, didUpdateWith: SCContentFilter(), for: nil)
        await eventually { cursorless.runningSourceCount == 1 }
        let systemSource = try XCTUnwrap(system.sources.first)
        let cursorlessSource = try XCTUnwrap(cursorless.sources.first)
        for driver in factory.drivers { driver.emit(try makeFrame()) }
        await eventually { systemSource.isPresentationVisible && cursorlessSource.isPresentationVisible }
        // Let the dummy picker's initial geometry settle first. An unrelated
        // later resize/replay must not be what eventually enables the laser.
        await eventually { factory.drivers.allSatisfy { !$0.updates.isEmpty } }
        system.setPointerStyle(.redDot)
        // The input is static: no more native callbacks arrive after joining it.
        await eventually {
            systemSource.renderers.stage.shouldSamplePointerLocation() &&
                systemSource.renderers.preview.shouldSamplePointerLocation()
        }
        XCTAssertEqual(factory.drivers.count, 2)
        XCTAssertEqual(pool.inputCount, 1)
        XCTAssertEqual(factory.drivers[1].starts, 1)
        await stopCoordinator(system)
        await stopCoordinator(cursorless)
    }

    @MainActor
    private func openCoordinator(pool: SharedCaptureStreamPool, filter: SCContentFilter) async throws -> CaptureCoordinator {
        let capture = CaptureCoordinator(acceptsNewSources: true, streamPool: pool)
        XCTAssertTrue(capture.beginPickerPresentation())
        capture.contentSharingPicker(.shared, didUpdateWith: filter, for: nil)
        await eventually { capture.sources.count == 1 && capture.runningSourceCount == 1 }
        return capture
    }

    @MainActor
    private func stopCoordinator(_ capture: CaptureCoordinator) async {
        await withCheckedContinuation { continuation in
            capture.stop { error in
                XCTAssertNil(error)
                continuation.resume()
            }
        }
    }

    @MainActor
    private func start(_ lease: CaptureStreamLease) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            lease.startCapture { error in if let error { c.resume(throwing: error) } else { c.resume() } }
        }
    }
    @MainActor
    private func stop(_ lease: CaptureStreamLease) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            lease.stopCapture { error in if let error { c.resume(throwing: error) } else { c.resume() } }
        }
    }
    @MainActor
    private func configure(_ lease: CaptureStreamLease, width: Int, height: Int, showsCursor: Bool = false) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            lease.updateConfiguration(CaptureStreamSettings(width: width, height: height, showsCursor: showsCursor).makeConfiguration()) {
                error in if let error { c.resume(throwing: error) } else { c.resume() }
            }
        }
    }
    @MainActor
    private func replace(_ lease: CaptureStreamLease, with filter: SCContentFilter) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            lease.updateContentFilter(filter) { error in if let error { c.resume(throwing: error) } else { c.resume() } }
        }
    }
    @MainActor
    private func eventually(_ predicate: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<200 {
            if predicate() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(predicate(), "Timed out waiting for capture state", file: file, line: line)
    }
    private func drain(_ queue: DispatchQueue) async {
        await withCheckedContinuation { c in queue.async { c.resume() } }
    }

    private func makeFrame(status: SCFrameStatus = .complete) throws -> Frame {
        let width = 64, height = 32
        var pixelBuffer: CVPixelBuffer?
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary, &pixelBuffer), kCVReturnSuccess)
        let pixels = try XCTUnwrap(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixels, [])
        let base = try XCTUnwrap(CVPixelBufferGetBaseAddress(pixels)).assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(pixels)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * stride + x * 4
                base[offset] = x >= width / 2 ? 255 : 0
                base[offset + 1] = x < width / 2 ? 255 : 0
                base[offset + 2] = 0
                base[offset + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(pixels, [])
        var format: CMVideoFormatDescription?
        XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
            imageBuffer: pixels, formatDescriptionOut: &format), noErr)
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        XCTAssertEqual(CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
            imageBuffer: pixels, formatDescription: try XCTUnwrap(format), sampleTiming: &timing, sampleBufferOut: &sample), noErr)
        let buffer = try XCTUnwrap(sample)
        let array = try XCTUnwrap(CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true))
        let attachments = unsafeBitCast(CFArrayGetValueAtIndex(array, 0), to: NSMutableDictionary.self)
        attachments[SCStreamFrameInfo.status.rawValue] = status.rawValue
        attachments[SCStreamFrameInfo.contentRect.rawValue] = CGRect(x: 0, y: 0, width: width, height: height).dictionaryRepresentation
        attachments[SCStreamFrameInfo.screenRect.rawValue] = CGRect(x: 0, y: 0, width: width, height: height).dictionaryRepresentation
        attachments[SCStreamFrameInfo.contentScale.rawValue] = CGFloat(1)
        attachments[SCStreamFrameInfo.scaleFactor.rawValue] = CGFloat(1)
        attachments[kCMSampleAttachmentKey_DisplayImmediately] = true
        return Frame(sample: buffer)
    }
}
