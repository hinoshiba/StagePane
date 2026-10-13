import AppKit
import StagePaneCore
import SwiftUI

/// Read-only artwork shared by Preview and Audience. Input stays in Workspace.
struct StageMagnifierOverlay: View {
    let entries: [StageCompositeEntry]
    let theme: StageTheme
    @ObservedObject var annotations: StageAnnotationStore
    let position: CGPoint?
    var magnification: Double = 2

    var body: some View {
        GeometryReader { proxy in
            if let position,
               let geometry = StageMagnifierGeometry(
                canvasSize: proxy.size,
                normalizedPosition: position,
                magnification: magnification
               ) {
                ZStack(alignment: .topLeading) {
                    magnifiedCanvas(geometry) {
                        StageBackground(theme: theme)
                    }
                    StageMagnifierSources(entries: entries, geometry: geometry)
                        .frame(
                            width: geometry.lensFrame.width,
                            height: geometry.lensFrame.height
                        )
                    magnifiedCanvas(geometry) {
                        StageAnnotationOverlay(store: annotations)
                    }
                }
                .frame(
                    width: geometry.lensFrame.width,
                    height: geometry.lensFrame.height,
                    alignment: .topLeading
                )
                .background(StageBackground(theme: theme))
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.9), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.35), radius: 7, y: 3)
                .position(x: geometry.lensFrame.midX, y: geometry.lensFrame.midY)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func magnifiedCanvas<Content: View>(
        _ geometry: StageMagnifierGeometry,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: geometry.canvasSize.width, height: geometry.canvasSize.height)
            .clipped()
            .scaleEffect(geometry.magnification, anchor: .topLeading)
            .offset(
                x: -geometry.sampledStageRect.minX * geometry.magnification,
                y: -geometry.sampledStageRect.minY * geometry.magnification
            )
            .frame(
                width: geometry.lensFrame.width,
                height: geometry.lensFrame.height,
                alignment: .topLeading
            )
            .clipped()
    }
}

private struct StageMagnifierSources: NSViewRepresentable {
    let entries: [StageCompositeEntry]
    let geometry: StageMagnifierGeometry

    func makeNSView(context: Context) -> StageMagnifierSourcesNSView {
        let view = StageMagnifierSourcesNSView()
        view.update(entries: entries, geometry: geometry)
        return view
    }

    func updateNSView(_ nsView: StageMagnifierSourcesNSView, context: Context) {
        nsView.update(entries: entries, geometry: geometry)
    }

    static func dismantleNSView(_ nsView: StageMagnifierSourcesNSView, coordinator: ()) {
        nsView.stop()
    }
}

/// Separate bitmap layers leave each zero-copy video layer with its one owner.
/// Normal backing layers also participate in the existing Audience PNG path.
final class StageMagnifierSourcesNSView: NSView {
    private struct Registration {
        let renderer: SampleBufferRenderer
        let observerID: UUID
    }

    private var entries: [StageCompositeEntry] = []
    private var geometry: StageMagnifierGeometry?
    private var sourceLayers: [StageSourceID: CALayer] = [:]
    private var registrations: [StageSourceID: Registration] = [:]
    private var refreshTimer: Timer?

    override var isOpaque: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        let backingLayer = CALayer()
        backingLayer.suppressImplicitPresentationActions()
        backingLayer.backgroundColor = NSColor.clear.cgColor
        backingLayer.masksToBounds = true
        layer = backingLayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for registration in registrations.values {
            registration.renderer.removePresentationGeometryObserver(registration.observerID)
        }
    }

    func update(entries: [StageCompositeEntry], geometry: StageMagnifierGeometry) {
        self.entries = entries
        self.geometry = geometry
        let wantedIDs = Set(entries.map(\.id))
        for id in Array(registrations.keys) where !wantedIDs.contains(id) {
            removeSource(id)
        }
        for entry in entries {
            if let old = registrations[entry.id], old.renderer !== entry.renderer {
                removeSource(entry.id)
            }
            if registrations[entry.id] == nil {
                let sourceID = entry.id
                let sourceLayer = CALayer()
                sourceLayer.suppressImplicitPresentationActions()
                sourceLayer.contentsGravity = .resize
                sourceLayers[entry.id] = sourceLayer
                let observerID = entry.renderer.addPresentationGeometryObserver {
                    [weak self] _ in
                    // Clear on every geometry boundary, including a newly
                    // published frame that has not yet been acknowledged.
                    // Refill only from the lock-validated snapshot API.
                    self?.sourceLayers[sourceID]?.contents = nil
                }
                registrations[entry.id] = Registration(
                    renderer: entry.renderer,
                    observerID: observerID
                )
            }
        }
        layer?.sublayers = entries.compactMap { sourceLayers[$0.id] }
        refreshFrames()
    }

    override func layout() {
        super.layout()
        refreshFrames()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshTimer?.invalidate()
        refreshTimer = nil
        guard window != nil else { return }
        let timer = Timer(timeInterval: 1 / 30, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            MainActor.assumeIsolated {
                guard self.window?.isVisible == true else { return }
                self.refreshFrames()
            }
        }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        refreshFrames()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        for id in Array(registrations.keys) {
            removeSource(id)
        }
    }

    /// May also be called synchronously by the Audience snapshotter before
    /// caching the view to avoid waiting for the next animation refresh.
    func refreshFrames() {
        guard let geometry, bounds.width > 0, bounds.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        for entry in entries {
            guard let sourceLayer = sourceLayers[entry.id] else { continue }
            let frame = CGRect(
                x: CGFloat(entry.frame.x) * geometry.canvasSize.width,
                y: CGFloat(entry.frame.y) * geometry.canvasSize.height,
                width: CGFloat(entry.frame.width) * geometry.canvasSize.width,
                height: CGFloat(entry.frame.height) * geometry.canvasSize.height
            )
            guard entry.isVisible,
                  let snapshot = entry.renderer.makeMagnifierSnapshot(
                    sourceCrop: entry.sourceCrop,
                    destinationFrame: frame,
                    magnifier: geometry,
                    backingScale: window?.backingScaleFactor ?? 2
                  ) else {
                sourceLayer.contents = nil
                continue
            }
            sourceLayer.frame = CGRect(
                x: snapshot.frame.minX,
                y: bounds.height - snapshot.frame.maxY,
                width: snapshot.frame.width,
                height: snapshot.frame.height
            )
            sourceLayer.contents = snapshot.image
        }
    }

    private func removeSource(_ id: StageSourceID) {
        if let registration = registrations.removeValue(forKey: id) {
            registration.renderer.removePresentationGeometryObserver(registration.observerID)
        }
        sourceLayers.removeValue(forKey: id)?.removeFromSuperlayer()
    }
}
