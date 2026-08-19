import AppKit
import StagePaneCore
import SwiftUI

struct StageCompositeEntry: Identifiable {
    let id: StageSourceID
    let frame: NormalizedStageRect
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
    private var sourceViews: [StageSourceID: SampleBufferNSView] = [:]
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
            let sourceView: SampleBufferNSView
            if let existing = sourceViews[entry.id] {
                sourceView = existing
            } else {
                sourceView = SampleBufferNSView(renderer: entry.renderer)
                sourceViews[entry.id] = sourceView
                addSubview(sourceView)
            }
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
