import AppKit
import StagePaneCore
import SwiftUI

/// Keeps the audience canvas in the selected Stage shape when its window has
/// another shape, including a native full-screen window. The same hosting
/// controller and media views remain installed throughout the transition.
@MainActor
final class StageCanvasHostViewController: NSViewController {
    private let hostingController: NSHostingController<StageView>
    private let canvasHost: StageCanvasHostView

    /// Both the drawing-size readout and Audience PNG use this inner canvas,
    /// excluding the surrounding full-screen matte. Finish the outer layout
    /// first so a snapshot immediately after resizing uses current geometry.
    var canvasView: NSView {
        canvasHost.layoutSubtreeIfNeeded()
        return hostingController.view
    }

    var onCanvasLayout: (() -> Void)? {
        get { canvasHost.onCanvasLayout }
        set { canvasHost.onCanvasLayout = newValue }
    }

    init(controller: AppController, capture: CaptureCoordinator) {
        hostingController = NSHostingController(
            rootView: StageView(controller: controller, capture: capture)
        )
        canvasHost = StageCanvasHostView(
            canvasView: hostingController.view,
            preset: controller.preset
        )
        super.init(nibName: nil, bundle: nil)
        addChild(hostingController)
        view = canvasHost
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPreset(_ preset: StagePreset) {
        canvasHost.setPreset(preset)
    }
}

@MainActor
private final class StageCanvasHostView: NSView {
    private let canvasView: NSView
    private var aspectRatio: Double
    private var layoutNotificationPending = false

    var onCanvasLayout: (() -> Void)? {
        didSet { notifyAfterLayout() }
    }

    override var isOpaque: Bool { true }

    init(canvasView: NSView, preset: StagePreset) {
        self.canvasView = canvasView
        aspectRatio = preset.aspectRatio
        super.init(frame: CGRect(
            origin: .zero,
            size: StageWindowSizing.suggestedContentSize(for: preset)
        ))
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true
        canvasView.autoresizingMask = []
        canvasView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(canvasView)
        needsLayout = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPreset(_ preset: StagePreset) {
        guard aspectRatio != preset.aspectRatio else { return }
        aspectRatio = preset.aspectRatio
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let frame = StageWindowSizing.fittedCanvasRect(
            in: bounds,
            aspectRatio: aspectRatio
        ) ?? .zero
        guard canvasView.frame != frame else { return }
        canvasView.frame = frame
        notifyAfterLayout()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
        notifyAfterLayout()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        notifyAfterLayout()
    }

    private func notifyAfterLayout() {
        guard onCanvasLayout != nil, !layoutNotificationPending else { return }
        layoutNotificationPending = true
        // A layout or backing notification may occur during a SwiftUI update.
        // Publish the readout only after that update, coalescing intermediate
        // full-screen animation sizes and using the latest canvas bounds.
        Task { @MainActor [weak self] in
            guard let self else { return }
            layoutSubtreeIfNeeded()
            layoutNotificationPending = false
            onCanvasLayout?()
        }
    }
}
