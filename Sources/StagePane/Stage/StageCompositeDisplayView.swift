import AppKit
import StagePaneCore
import SwiftUI

struct StageCompositeEntry: Identifiable {
    let id: StageSourceID
    let frame: NormalizedStageRect
    let sourceCrop: NormalizedSourceRect
    let renderer: SampleBufferRenderer
}

struct StageCompositeDisplayView: NSViewRepresentable {
    let entries: [StageCompositeEntry]

    func makeNSView(context: Context) -> StageCompositeNSView {
        let view = StageCompositeNSView()
        view.update(entries: entries)
        return view
    }

    func updateNSView(_ nsView: StageCompositeNSView, context: Context) {
        nsView.update(entries: entries)
    }
}

final class StageCompositeNSView: NSView {
    private var sourceViews: [StageSourceID: CroppedSampleBufferNSView] = [:]
    private var sourceFrames: [StageSourceID: NormalizedStageRect] = [:]

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(entries: [StageCompositeEntry]) {
        // Entries are ordered back-to-front. Disable the previous owner before
        // enabling the new one so overlapping or duplicate sources can never
        // show more than one local red-dot pointer during a z-order change.
        let pointerSourceID = entries.last?.id
        for (sourceID, sourceView) in sourceViews where sourceID != pointerSourceID {
            sourceView.setPointerOverlayEnabled(false)
        }

        let wantedIDs = Set(entries.map(\.id))
        let removedIDs = sourceViews.keys.filter { !wantedIDs.contains($0) }
        for sourceID in removedIDs {
            sourceViews[sourceID]?.setPointerOverlayEnabled(false)
            sourceViews[sourceID]?.removeFromSuperview()
            sourceViews.removeValue(forKey: sourceID)
            sourceFrames.removeValue(forKey: sourceID)
        }

        var previousView: NSView?
        for entry in entries {
            let sourceView: CroppedSampleBufferNSView
            if let existing = sourceViews[entry.id] {
                sourceView = existing
            } else {
                sourceView = CroppedSampleBufferNSView(renderer: entry.renderer)
                sourceViews[entry.id] = sourceView
                addSubview(sourceView)
            }
            sourceView.update(sourceCrop: entry.sourceCrop)
            sourceFrames[entry.id] = entry.frame

            if let previousView {
                addSubview(sourceView, positioned: .above, relativeTo: previousView)
            } else {
                addSubview(sourceView, positioned: .below, relativeTo: nil)
            }
            previousView = sourceView
        }
        if let pointerSourceID {
            sourceViews[pointerSourceID]?.setPointerOverlayEnabled(true)
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        for (sourceID, sourceView) in sourceViews {
            guard let normalized = sourceFrames[sourceID] else { continue }
            sourceView.frame = CGRect(
                x: bounds.width * CGFloat(normalized.x),
                y: bounds.height * CGFloat(normalized.y),
                width: bounds.width * CGFloat(normalized.width),
                height: bounds.height * CGFloat(normalized.height)
            )
        }
    }
}

/// Clips a complete picker-authorized source view to one local composition
/// region. The child view remains the owner of video, pointer, and bitmap
/// snapshot artwork, so every audience-facing path shares the same crop.
final class CroppedSampleBufferNSView: NSView {
    private let renderer: SampleBufferRenderer
    private let sourceView: SampleBufferNSView
    private var sourceCrop = NormalizedSourceRect.fullSource
    private var presentationGeometry: SourcePresentationGeometry?
    private var presentationRevision: UInt64?
    private var presentationGeometryObserverID: UUID?

    override var isFlipped: Bool { true }

    init(renderer: SampleBufferRenderer) {
        self.renderer = renderer
        self.sourceView = SampleBufferNSView(renderer: renderer)
        super.init(frame: .zero)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true
        addSubview(sourceView)
        presentationGeometryObserverID = renderer.addPresentationGeometryObserver {
            [weak self] update in
            self?.presentationGeometryDidChange(update)
        }
    }

    deinit {
        if let presentationGeometryObserverID {
            renderer.removePresentationGeometryObserver(presentationGeometryObserverID)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(sourceCrop: NormalizedSourceRect) {
        self.sourceCrop = sourceCrop
        applyPresentationLayout(using: presentationGeometry)
        needsLayout = true
    }

    func setPointerOverlayEnabled(_ enabled: Bool) {
        sourceView.setPointerOverlayEnabled(enabled)
    }

    /// Produces and installs screenshots through the same crop wrapper used by
    /// the live Stage. A non-full crop is not exportable until the retained
    /// pixel buffer has matching presentation geometry; returning nil preserves
    /// the snapshotter's existing complete-frame requirement.
    func makeBitmapSnapshotImage() -> CGImage? {
        guard let image = sourceView.makeBitmapSnapshotImage(),
              !sourceView.isHidden else { return nil }
        return image
    }

    func installBitmapSnapshotImage(
        _ image: CGImage
    ) -> SampleBufferBitmapSnapshotLayerState? {
        sourceView.installBitmapSnapshotImage(image)
    }

    override func layout() {
        super.layout()
        applyPresentationLayout(using: presentationGeometry)
    }

    /// Called synchronously while the Audience snapshotter holds a pixel buffer
    /// and geometry copied from the same renderer lock. Applying the frame
    /// directly avoids a later layout query racing ahead to a newer IOSurface.
    func synchronizeSnapshotGeometry(_ geometry: SourcePresentationGeometry?) {
        presentationGeometry = geometry
        applyPresentationLayout(using: geometry)
    }

    private func applyPresentationLayout(
        using presentationGeometry: SourcePresentationGeometry?
    ) {
        guard let presentationGeometry else {
            sourceView.frame = bounds
            // A geometry transition suppresses full-source and cropped views
            // alike. Revealing even an identity crop before its MainActor
            // acknowledgement could expose a newly enqueued padded IOSurface
            // through layout retained from the previous accepted frame.
            sourceView.isHidden = true
            sourceView.setVisibleSurfaceCrop(nil)
            return
        }

        guard let frame = SourceCropProjection.sourceFrame(
            presentation: presentationGeometry,
            sourceCrop: sourceCrop,
            destinationSize: bounds.size
        ), let surfaceCrop = SourceCropProjection.surfaceCropRect(
            presentation: presentationGeometry,
            sourceCrop: sourceCrop
        ) else {
            sourceView.isHidden = true
            sourceView.setVisibleSurfaceCrop(nil)
            sourceView.frame = bounds
            return
        }

        sourceView.frame = frame
        sourceView.setVisibleSurfaceCrop(surfaceCrop)
        sourceView.isHidden = false
    }

    private func presentationGeometryDidChange(
        _ update: PresentationGeometryUpdate
    ) {
        if let presentationRevision,
           update.revision < presentationRevision { return }
        presentationRevision = update.revision
        presentationGeometry = update.geometry
        applyPresentationLayout(using: update.geometry)
        needsLayout = true
    }
}
