import AppKit
import AVFoundation
import CoreMedia
import ScreenCaptureKit

/// Owns the zero-copy display layer used by the public share stage.
///
/// `AVSampleBufferVideoRenderer` is the macOS 14 API intended for safely
/// enqueueing buffers away from the main thread. All renderer state and all
/// sample-buffer operations are confined to `renderQueue`; AppKit only touches
/// the layer hierarchy on the main thread.
final class SampleBufferRenderer: @unchecked Sendable {
    let displayLayer: AVSampleBufferDisplayLayer

    private let videoRenderer: AVSampleBufferVideoRenderer
    private let renderQueue: DispatchQueue
    private var desiredToken: UUID?
    private var activeToken: UUID?

    init(renderQueue: DispatchQueue) {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = NSColor.black.cgColor
        layer.preventsCapture = false

        self.displayLayer = layer
        self.videoRenderer = layer.sampleBufferRenderer
        self.renderQueue = renderQueue
    }

    /// Makes a stream's frames eligible for display. Frames received while the
    /// renderer is resetting are intentionally dropped; the next live frame
    /// becomes the new image without ever exposing a previous stream's frame.
    func activate(token: UUID) {
        renderQueue.async { [self] in
            desiredToken = token
            activeToken = nil
            videoRenderer.flush(removingDisplayedImage: true) { [weak self] in
                guard let self else { return }
                self.renderQueue.async {
                    guard self.desiredToken == token else { return }
                    self.activeToken = token
                }
            }
        }
    }

    /// Invalidates a stream before asynchronous ScreenCaptureKit teardown.
    /// The callback runs only after queued frame callbacks have drained and the
    /// displayed image has been removed.
    func deactivate(token: UUID, completion: (@Sendable () -> Void)? = nil) {
        renderQueue.async { [self] in
            if desiredToken == token { desiredToken = nil }
            if activeToken == token { activeToken = nil }
            videoRenderer.flush(removingDisplayedImage: true) {
                completion?()
            }
        }
    }

    func flush(completion: (@Sendable () -> Void)? = nil) {
        renderQueue.async { [self] in
            desiredToken = nil
            activeToken = nil
            videoRenderer.flush(removingDisplayedImage: true) {
                completion?()
            }
        }
    }

    /// Called synchronously by a per-stream output proxy on `renderQueue`.
    /// There is deliberately no additional dispatch hop or backlog: if AVF is
    /// not ready, the real-time frame is dropped and a future frame replaces it.
    func enqueue(_ sampleBuffer: CMSampleBuffer, token: UUID) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token,
              sampleBuffer.isValid,
              CMSampleBufferGetImageBuffer(sampleBuffer) != nil,
              isCompleteFrame(sampleBuffer) else { return }

        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            videoRenderer.flush()
        }
        guard videoRenderer.isReadyForMoreMediaData else { return }
        videoRenderer.enqueue(sampleBuffer)
    }

    private func isCompleteFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: false
        ) as? [[SCStreamFrameInfo: Any]],
        let attachments = attachmentsArray.first,
        let rawStatus = attachments[.status] as? Int,
        let status = SCFrameStatus(rawValue: rawStatus) else {
            return false
        }
        return status == .complete
    }
}

final class SampleBufferNSView: NSView {
    private let renderer: SampleBufferRenderer

    init(renderer: SampleBufferRenderer) {
        self.renderer = renderer
        super.init(frame: .zero)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(renderer.displayLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        renderer.displayLayer.frame = bounds
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if renderer.displayLayer.superlayer !== layer {
            renderer.displayLayer.removeFromSuperlayer()
            layer?.addSublayer(renderer.displayLayer)
        }
        renderer.displayLayer.frame = bounds
    }
}
