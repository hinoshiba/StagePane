import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit

/// Only a picker-authorized single window has a reliable cross-selection key.
/// Older systems and application/display filters reuse only the same filter
/// object; titles, geometry, and application names are never identity evidence.
enum CaptureInputIdentity: Hashable {
    case window(id: CGWindowID, processID: pid_t)
    case filter(ObjectIdentifier)

    static func authorizedInput(_ filter: SCContentFilter) -> Self {
        if #available(macOS 15.2, *), filter.style == .window,
           filter.includedWindows.count == 1,
           let window = filter.includedWindows.first,
           window.windowID != 0, let app = window.owningApplication,
           app.processID > 0 {
            return .window(id: window.windowID, processID: app.processID)
        }
        return .filter(ObjectIdentifier(filter))
    }
}

struct CaptureStreamSettings: Equatable, Sendable {
    let width: Int
    let height: Int
    let showsCursor: Bool

    init(width: Int, height: Int, showsCursor: Bool) {
        self.width = width
        self.height = height
        self.showsCursor = showsCursor
    }

    init(_ configuration: SCStreamConfiguration) {
        self.init(width: configuration.width, height: configuration.height,
                  showsCursor: configuration.showsCursor)
    }

    // SCStreamConfiguration does not retain this color.
    private static let backgroundColor = CGColor(gray: 0, alpha: 1)

    func makeConfiguration() -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        configuration.width = width
        configuration.height = height
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.queueDepth = 3
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.scalesToFit = true
        configuration.preservesAspectRatio = true
        configuration.showsCursor = showsCursor
        configuration.capturesAudio = false
        configuration.backgroundColor = Self.backgroundColor
        configuration.shouldBeOpaque = true
        configuration.ignoreShadowsSingleWindow = true
        configuration.ignoreGlobalClipSingleWindow = true
        configuration.captureResolution = .best
        configuration.streamName = "StagePane Local Source"
        if #available(macOS 14.2, *) { configuration.includeChildWindows = true }
        return configuration
    }
}

/// Native operations are injectable so lifecycle tests never capture the desktop.
@MainActor
protocol SharedCaptureStreamDriver: AnyObject {
    var stream: SCStream { get }
    func start() async throws
    func stop() async throws
    func update(_ settings: CaptureStreamSettings) async throws
    func removeOutput() throws
}

@MainActor
private final class NativeCaptureStreamDriver: SharedCaptureStreamDriver {
    let stream: SCStream
    private let output: SharedCaptureStreamOutput

    init(filter: SCContentFilter, settings: CaptureStreamSettings, output: SharedCaptureStreamOutput) throws {
        self.output = output
        stream = SCStream(filter: filter, configuration: settings.makeConfiguration(), delegate: output)
        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: output.queue)
    }

    func start() async throws { try await stream.startCapture() }
    func stop() async throws { try await stream.stopCapture() }
    func update(_ settings: CaptureStreamSettings) async throws {
        try await stream.updateConfiguration(settings.makeConfiguration())
    }
    func removeOutput() throws { try stream.removeStreamOutput(output, type: .screen) }
}

/// One lease has its own delivery fence and renderer queue. Queued callbacks
/// from a detached input cannot cross into the lease's replacement input.
final class CaptureStreamDelivery: @unchecked Sendable {
    private let lock = NSLock()
    private var binding: UUID?
    private var acceptsFrames = false
    let proxy: CaptureStreamProxy
    private let queue: DispatchQueue

    init(proxy: CaptureStreamProxy, queue: DispatchQueue) {
        self.proxy = proxy
        self.queue = queue
    }

    func bind(_ binding: UUID, active: Bool) {
        lock.lock()
        self.binding = binding
        acceptsFrames = active
        lock.unlock()
    }

    func setActive(_ active: Bool) {
        lock.lock()
        acceptsFrames = active
        lock.unlock()
    }

    func unbind() {
        lock.lock()
        binding = nil
        acceptsFrames = false
        lock.unlock()
    }

    func frame(_ sample: CMSampleBuffer, stream: SCStream, binding: UUID) {
        lock.lock()
        let shouldDeliver = self.binding == binding && acceptsFrames
        lock.unlock()
        guard shouldDeliver else { return }
        let sampleBox = SendableBox(sample)
        let streamBox = SendableBox(stream)
        queue.async { [self] in
            lock.lock()
            defer { lock.unlock() }
            guard self.binding == binding, acceptsFrames else { return }
            proxy.stream(streamBox.value, didOutputSampleBuffer: sampleBox.value, of: .screen)
        }
    }

    func unavailable(binding: UUID) {
        queue.async { [self] in
            lock.lock()
            defer { lock.unlock() }
            guard self.binding == binding, acceptsFrames else { return }
            proxy.inputBecameUnavailableOnOutputQueue()
        }
    }

    func stopped(_ stream: SCStream, error: Error, binding: UUID) {
        lock.lock()
        guard self.binding == binding else { lock.unlock(); return }
        acceptsFrames = false
        proxy.revokeInputSnapshots()
        lock.unlock()
        let streamBox = SendableBox(stream)
        let failure = StreamStopFailure(error)
        queue.async { [self] in
            lock.lock()
            defer { lock.unlock() }
            guard self.binding == binding else { return }
            proxy.inputStoppedOnOutputQueue(streamBox.value, failure: failure)
        }
    }
}

/// One ScreenCaptureKit callback fans out the exact IOSurface-backed buffer.
/// A single retained complete frame lets a new subscriber see a static window
/// immediately. Blank/inactive/stop boundaries revoke that retained frame.
final class SharedCaptureStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "com.hinoshiba.stagepane.shared-input", qos: .userInteractive)
    private let lock = NSLock()
    private var clients: [UUID: CaptureStreamDelivery] = [:]
    private var latestFrame: CMSampleBuffer?
    private var ended = false
    private var acceptsFrames = false

    var hasEnded: Bool {
        lock.lock()
        defer { lock.unlock() }
        return ended
    }

    func attach(_ delivery: CaptureStreamDelivery, binding: UUID) {
        lock.lock()
        clients[binding] = delivery
        lock.unlock()
    }

    func detach(_ binding: UUID) {
        lock.lock()
        clients.removeValue(forKey: binding)
        lock.unlock()
    }

    func clearRetainedFrame() {
        lock.lock()
        latestFrame = nil
        lock.unlock()
    }

    func suspendCaptureDelivery() {
        lock.lock()
        acceptsFrames = false
        latestFrame = nil
        lock.unlock()
    }

    func resumeCaptureDelivery() async {
        // Drain callbacks queued before the previous stop before accepting
        // frames from a restarted native stream.
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                lock.lock()
                latestFrame = nil
                acceptsFrames = !ended
                lock.unlock()
                continuation.resume()
            }
        }
    }

    func replay(to delivery: CaptureStreamDelivery, binding: UUID, stream: SCStream) {
        lock.lock()
        defer { lock.unlock() }
        guard !ended, acceptsFrames, clients[binding] === delivery, let latestFrame else { return }
        delivery.frame(latestFrame, stream: stream, binding: binding)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        lock.lock()
        defer { lock.unlock() }
        guard !ended, acceptsFrames else { return }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
           let rawStatus = attachments.first?[.status] as? Int,
           let status = SCFrameStatus(rawValue: rawStatus) {
            switch status {
            case .complete:
                latestFrame = sampleBuffer.isValid && CMSampleBufferGetImageBuffer(sampleBuffer) != nil ? sampleBuffer : nil
            case .blank, .suspended, .stopped:
                latestFrame = nil
            default: break
            }
        }
        for (binding, delivery) in clients {
            delivery.frame(sampleBuffer, stream: stream, binding: binding)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        lock.lock()
        ended = true
        acceptsFrames = false
        latestFrame = nil
        let targets = clients
        lock.unlock()
        for (binding, delivery) in targets { delivery.stopped(stream, error: error, binding: binding) }
    }

    @available(macOS 15.2, *)
    func streamDidBecomeInactive(_ stream: SCStream) {
        lock.lock()
        defer { lock.unlock() }
        latestFrame = nil
        // Keep this boundary ordered with complete frames and replay. A frame
        // accepted after it must reach each renderer after invalidation too.
        for (binding, delivery) in clients { delivery.unavailable(binding: binding) }
    }
}

private struct SharedCaptureKey: Hashable {
    let input: CaptureInputIdentity
    // Native cursors are baked into pixels. A cursorless consumer must never
    // receive those frames; differing cursor modes require separate inputs.
    let showsCursor: Bool
}

@MainActor
private final class SharedCaptureEntry {
    struct Client {
        weak var lease: CaptureStreamLease?
        let delivery: CaptureStreamDelivery
        let binding: UUID
    }
    let key: SharedCaptureKey
    let driver: any SharedCaptureStreamDriver
    let output: SharedCaptureStreamOutput
    var clients: [UUID: Client] = [:]
    var settings: CaptureStreamSettings
    var running = false
    var startFailed = false

    init(key: SharedCaptureKey, driver: any SharedCaptureStreamDriver,
         output: SharedCaptureStreamOutput, settings: CaptureStreamSettings) {
        self.key = key
        self.driver = driver
        self.output = output
        self.settings = settings
    }
}

/// Serializes native lifecycle/configuration operations; frame delivery remains
/// independent on each input and renderer queue. Consumers retain independent
/// crop, placement, color effects, and presentation generations.
@MainActor
final class SharedCaptureStreamPool {
    static let shared = SharedCaptureStreamPool()
    typealias DriverFactory = @MainActor (SCContentFilter, CaptureStreamSettings, SharedCaptureStreamOutput) throws -> any SharedCaptureStreamDriver
    private let factory: DriverFactory
    private let identify: (SCContentFilter) -> CaptureInputIdentity
    private var entries: [SharedCaptureKey: SharedCaptureEntry] = [:]
    private var operationTail: Task<Void, Never>?
    private var cleanupRetries: Set<ObjectIdentifier> = []

    var inputCount: Int { entries.count }
    var runningInputCount: Int { entries.values.filter { $0.running && !$0.output.hasEnded }.count }

    init(
        identify: @escaping (SCContentFilter) -> CaptureInputIdentity = CaptureInputIdentity.authorizedInput,
        factory: @escaping DriverFactory = { try NativeCaptureStreamDriver(filter: $0, settings: $1, output: $2) }
    ) {
        self.identify = identify
        self.factory = factory
    }

    func acquire(filter: SCContentFilter, configuration: SCStreamConfiguration,
                 proxy: CaptureStreamProxy, queue: DispatchQueue) throws -> CaptureStreamLease {
        let settings = CaptureStreamSettings(configuration)
        let entry = try entry(for: filter, settings: settings)
        let lease = CaptureStreamLease(pool: self, filter: filter, settings: settings,
                                       entry: entry, delivery: CaptureStreamDelivery(proxy: proxy, queue: queue))
        attach(lease, to: entry)
        return lease
    }

    private func entry(for filter: SCContentFilter, settings: CaptureStreamSettings) throws -> SharedCaptureEntry {
        let key = SharedCaptureKey(input: identify(filter), showsCursor: settings.showsCursor)
        if let entry = entries[key], !entry.output.hasEnded { return entry }
        let output = SharedCaptureStreamOutput()
        let driver = try factory(filter, settings, output)
        let entry = SharedCaptureEntry(key: key, driver: driver, output: output, settings: settings)
        entries[key] = entry
        return entry
    }

    fileprivate func enqueue(_ action: @escaping @MainActor () async -> Void) {
        let preceding = operationTail
        operationTail = Task { @MainActor in
            await preceding?.value
            await action()
        }
    }

    private func attach(_ lease: CaptureStreamLease, to entry: SharedCaptureEntry) {
        let binding = UUID()
        lease.entry = entry
        lease.binding = binding
        lease.delivery.bind(binding, active: false)
        entry.clients[lease.id] = .init(lease: lease, delivery: lease.delivery, binding: binding)
        entry.output.attach(lease.delivery, binding: binding)
    }

    private func aggregateSettings(_ entry: SharedCaptureEntry) -> CaptureStreamSettings {
        let active = entry.clients.values.compactMap(\.lease).filter(\.active)
        return CaptureStreamSettings(
            width: active.map(\.settings.width).max() ?? entry.settings.width,
            height: active.map(\.settings.height).max() ?? entry.settings.height,
            showsCursor: entry.key.showsCursor
        )
    }

    private func configure(_ entry: SharedCaptureEntry) async throws {
        let desired = aggregateSettings(entry)
        guard desired != entry.settings else { return }
        try await entry.driver.update(desired)
        guard !entry.output.hasEnded else { throw CaptureLeaseError.ended }
        entry.settings = desired
    }

    fileprivate func start(_ lease: CaptureStreamLease) async throws {
        guard !lease.released, !lease.entry.output.hasEnded else { throw CaptureLeaseError.ended }
        let entry = lease.entry
        guard !entry.startFailed else { throw CaptureLeaseError.cleanupRequired }
        lease.active = true
        do {
            try await configure(entry)
            if !entry.running {
                await entry.output.resumeCaptureDelivery()
                // A failed start can still require native cleanup. Retain a
                // conservative running flag until stop confirms teardown.
                entry.running = true
                do { try await entry.driver.start() }
                catch {
                    entry.startFailed = true
                    entry.output.suspendCaptureDelivery()
                    throw error
                }
            }
            guard !lease.released, !entry.output.hasEnded else { throw CaptureLeaseError.ended }
            lease.delivery.setActive(true)
        } catch {
            lease.active = false
            lease.delivery.setActive(false)
            throw error
        }
    }

    fileprivate func stop(_ lease: CaptureStreamLease) async throws {
        guard !lease.released else { return }
        let entry = lease.entry
        lease.delivery.setActive(false)
        let wasActive = lease.active
        lease.active = false
        guard entry.running, !entry.output.hasEnded else { return }
        guard !entry.clients.values.compactMap(\.lease).contains(where: \.active) else {
            // Shrinking is optional. Keep the valid larger surface if the OS
            // rejects a shrink; another consumer must not fail because of Pause.
            try? await configure(entry)
            return
        }
        entry.output.suspendCaptureDelivery()
        do {
            try await entry.driver.stop()
            entry.running = false
            entry.startFailed = false
        } catch {
            let failure = error as NSError
            if entry.startFailed, failure.domain == SCStreamError.errorDomain,
               failure.code == SCStreamError.Code.attemptToStopStreamState.rawValue {
                // A failed initial start may leave no native stream to stop.
                entry.running = false
                entry.startFailed = false
                return
            }
            lease.active = wasActive
            if !entry.startFailed { await entry.output.resumeCaptureDelivery() }
            lease.delivery.setActive(wasActive)
            throw error
        }
    }

    fileprivate func update(_ lease: CaptureStreamLease, settings: CaptureStreamSettings) async throws {
        guard !lease.released, !lease.entry.output.hasEnded else { throw CaptureLeaseError.ended }
        if lease.settings.showsCursor != settings.showsCursor {
            try await migrate(lease, filter: lease.filter, settings: settings)
            return
        }
        let previous = lease.settings
        lease.settings = settings
        do { try await configure(lease.entry) }
        catch { lease.settings = previous; throw error }
    }

    fileprivate func replace(_ lease: CaptureStreamLease, filter: SCContentFilter) async throws {
        try await migrate(lease, filter: filter, settings: lease.settings)
    }

    private func migrate(_ lease: CaptureStreamLease, filter: SCContentFilter, settings: CaptureStreamSettings) async throws {
        guard !lease.released, !lease.entry.output.hasEnded else { throw CaptureLeaseError.ended }
        let key = SharedCaptureKey(input: identify(filter), showsCursor: settings.showsCursor)
        if key == lease.entry.key {
            lease.filter = filter
            try await update(lease, settings: settings)
            return
        }
        let wasActive = lease.active
        try await stop(lease)
        guard !lease.released, !lease.entry.output.hasEnded else { throw CaptureLeaseError.ended }
        // A failed allocation leaves the old, stopped lease available for the
        // coordinator's normal teardown; it never repoints another subscriber.
        let next = try entry(for: filter, settings: settings)
        do { try detach(lease) }
        catch { try? discardIfUnused(next); throw error }
        lease.filter = filter
        lease.settings = settings
        attach(lease, to: next)
        if wasActive { try await start(lease) }
    }

    private func detach(_ lease: CaptureStreamLease) throws {
        let entry = lease.entry
        lease.delivery.unbind()
        entry.output.detach(lease.binding)
        entry.clients.removeValue(forKey: lease.id)
        try discardIfUnused(entry)
    }

    private func discardIfUnused(_ entry: SharedCaptureEntry) throws {
        guard entry.clients.isEmpty else { return }
        guard !entry.running || entry.output.hasEnded else { throw CaptureLeaseError.stillActive }
        if entries[entry.key] === entry { entries.removeValue(forKey: entry.key) }
        entry.output.clearRetainedFrame()
        try entry.driver.removeOutput()
    }

    fileprivate func release(_ lease: CaptureStreamLease) throws {
        guard !lease.released else { return }
        guard (!lease.active && !lease.needsStopBeforeRelease) || lease.entry.output.hasEnded else {
            throw CaptureLeaseError.stillActive
        }
        lease.released = true
        try detach(lease)
    }

    fileprivate func abandon(_ id: UUID, entry: SharedCaptureEntry) {
        enqueue { [self] in
            guard let client = entry.clients[id], client.lease == nil else { return }
            client.delivery.unbind()
            entry.output.detach(client.binding)
            entry.clients.removeValue(forKey: id)
            await cleanUpAbandonedInput(entry)
        }
    }

    private func cleanUpAbandonedInput(_ entry: SharedCaptureEntry) async {
        guard !entry.clients.values.compactMap(\.lease).contains(where: \.active) else { return }
        if entry.running && !entry.output.hasEnded {
            entry.output.suspendCaptureDelivery()
            do {
                try await entry.driver.stop()
                entry.running = false
                entry.startFailed = false
            } catch {
                let failure = error as NSError
                if entry.startFailed, failure.domain == SCStreamError.errorDomain,
                   failure.code == SCStreamError.Code.attemptToStopStreamState.rawValue {
                    entry.running = false
                    entry.startFailed = false
                } else {
                    // Normal teardown retains the owning coordinator for a
                    // user retry. Unexpected owner deallocation must also
                    // keep cleanup alive, including when only paused leases remain.
                    let id = ObjectIdentifier(entry)
                    guard cleanupRetries.insert(id).inserted else { return }
                    Task { @MainActor [self] in
                        try? await Task.sleep(for: .seconds(1))
                        cleanupRetries.remove(id)
                        enqueue { [self] in await cleanUpAbandonedInput(entry) }
                    }
                    return
                }
            }
        }
        try? discardIfUnused(entry)
    }
}

private enum CaptureLeaseError: LocalizedError {
    case ended
    case stillActive
    case cleanupRequired
    var errorDescription: String? {
        switch self {
        case .ended: "The capture input has ended. Select its source again."
        case .stillActive: "The capture consumer must stop before its output is removed."
        case .cleanupRequired: "The previous capture start failed. Stop this input before trying again."
        }
    }
}

/// A stable logical stream identity for one layer. Its native input can migrate
/// without disturbing any other layer that was using the previous input.
@MainActor
final class CaptureStreamLease: @unchecked Sendable {
    fileprivate let id = UUID()
    private let pool: SharedCaptureStreamPool
    fileprivate var filter: SCContentFilter
    fileprivate var settings: CaptureStreamSettings
    fileprivate var entry: SharedCaptureEntry
    fileprivate var binding = UUID()
    fileprivate let delivery: CaptureStreamDelivery
    fileprivate var active = false
    fileprivate var released = false

    var nativeStream: SCStream { entry.driver.stream }
    var needsStopBeforeRelease: Bool {
        !released && entry.running && !entry.output.hasEnded &&
            !entry.clients.values.compactMap(\.lease).contains { $0 !== self && $0.active }
    }

    fileprivate init(pool: SharedCaptureStreamPool, filter: SCContentFilter, settings: CaptureStreamSettings,
                     entry: SharedCaptureEntry, delivery: CaptureStreamDelivery) {
        self.pool = pool
        self.filter = filter
        self.settings = settings
        self.entry = entry
        self.delivery = delivery
    }

    deinit {
        guard !released else { return }
        let pool = pool
        let id = id
        let entry = entry
        Task { @MainActor in pool.abandon(id, entry: entry) }
    }

    func replayCurrentFrame() {
        guard active, !released else { return }
        entry.output.replay(to: delivery, binding: binding, stream: nativeStream)
    }

    nonisolated func startCapture(completionHandler: @escaping @Sendable (Error?) -> Void) {
        Task { @MainActor in
            pool.enqueue { [self] in
                do { try await pool.start(self); completionHandler(nil); replayCurrentFrame() }
                catch { completionHandler(error) }
            }
        }
    }

    nonisolated func stopCapture(completionHandler: @escaping @Sendable (Error?) -> Void) {
        Task { @MainActor in
            pool.enqueue { [self] in
                do { try await pool.stop(self); completionHandler(nil) }
                catch { completionHandler(error) }
            }
        }
    }

    nonisolated func updateConfiguration(_ configuration: SCStreamConfiguration, completionHandler: @escaping @Sendable (Error?) -> Void) {
        let settings = CaptureStreamSettings(configuration)
        Task { @MainActor in
            pool.enqueue { [self] in
                // The coordinator replays after committing native-cursor
                // state on its renderer queue. Replaying here could label a
                // cursorless static frame with the previous cursor mode.
                do { try await pool.update(self, settings: settings); completionHandler(nil) }
                catch { completionHandler(error) }
            }
        }
    }

    nonisolated func updateContentFilter(_ filter: SCContentFilter, completionHandler: @escaping @Sendable (Error?) -> Void) {
        let box = SendableBox(filter)
        Task { @MainActor in
            pool.enqueue { [self] in
                do { try await pool.replace(self, filter: box.value); completionHandler(nil); replayCurrentFrame() }
                catch { completionHandler(error) }
            }
        }
    }

    func removeStreamOutput() throws { try pool.release(self) }
}
