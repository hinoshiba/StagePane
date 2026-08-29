import AppKit
import QuartzCore
import StagePaneCore

enum StageWindowSnapshotError: LocalizedError, Equatable {
    case missingContentView
    case invalidContentBounds
    case sourceFrameUnavailable(index: Int)
    case sourceBackingLayerUnavailable(index: Int)
    case bitmapAllocationFailed
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .missingContentView:
            "The Stage window has no content to capture."
        case .invalidContentBounds:
            "The Stage must have a visible, nonzero canvas size before taking a screenshot."
        case let .sourceFrameUnavailable(index):
            "Stage source \(index + 1) does not have a complete frame yet."
        case let .sourceBackingLayerUnavailable(index):
            "Stage source \(index + 1) is not ready to render a screenshot."
        case .bitmapAllocationFailed:
            "The Stage screenshot bitmap could not be allocated."
        case .imageEncodingFailed:
            "The Stage screenshot could not be encoded as PNG."
        }
    }
}

/// An immutable, clean Stage capture ready for clipboard or file export.
struct StageSnapshot {
    let image: CGImage
    let pngData: Data

    var pixelWidth: Int { image.width }
    var pixelHeight: Int { image.height }

    func writePNG(to url: URL) throws {
        try pngData.write(to: url, options: .atomic)
    }

    /// Places the lossless PNG itself on the pasteboard instead of asking
    /// AppKit to re-encode an `NSImage` as TIFF.
    @MainActor
    @discardableResult
    func copyPNG(to pasteboard: NSPasteboard = .general) -> Bool {
        let item = NSPasteboardItem()
        guard item.setData(pngData, forType: .png) else { return false }
        pasteboard.clearContents()
        return pasteboard.writeObjects([item])
    }
}

/// Captures only the Stage window's content view, excluding window chrome and
/// every private editor/control surface.
///
/// `NSView.cacheDisplay(in:to:)` includes the SwiftUI artwork, annotations,
/// watermark, curtain, safe-area guide, and pointer layer, but it cannot
/// rasterize `AVSampleBufferDisplayLayer`. For the duration of this one
/// synchronous main-actor call, each media layer is hidden (never removed) and
/// its already-authorized latest frame is installed as immutable backing-layer
/// contents. Every layer mutation is restored in `defer` before the main actor
/// can process another event.
@MainActor
enum StageWindowSnapshotter {
    static func capture(
        window: NSWindow,
        outputSize: StageSnapshotSize? = nil
    ) throws -> StageSnapshot {
        guard let contentView = window.contentView else {
            throw StageWindowSnapshotError.missingContentView
        }
        return try capture(contentView: contentView, outputSize: outputSize)
    }

    static func capture(
        contentView: NSView,
        outputSize: StageSnapshotSize? = nil
    ) throws -> StageSnapshot {
        contentView.layoutSubtreeIfNeeded()
        contentView.displayIfNeeded()

        let bounds = contentView.bounds
        guard bounds.width.isFinite,
              bounds.height.isFinite,
              bounds.width > 0,
              bounds.height > 0 else {
            throw StageWindowSnapshotError.invalidContentBounds
        }

        let sourceViews = visibleCroppedSourceViews(in: contentView)
        let sourceImages = try sourceViews.enumerated().map { index, sourceView in
            guard let image = sourceView.makeBitmapSnapshotImage() else {
                throw StageWindowSnapshotError.sourceFrameUnavailable(index: index)
            }
            return image
        }

        let bitmap: NSBitmapImageRep
        do {
            var restorationStates: [SampleBufferBitmapSnapshotLayerState] = []
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            defer {
                for state in restorationStates.reversed() {
                    state.restore()
                }
                CATransaction.commit()
            }

            for (index, pair) in zip(sourceViews, sourceImages).enumerated() {
                guard let state = pair.0.installBitmapSnapshotImage(pair.1) else {
                    throw StageWindowSnapshotError.sourceBackingLayerUnavailable(
                        index: index
                    )
                }
                restorationStates.append(state)
            }

            bitmap = try makeBitmap(
                for: contentView,
                bounds: bounds,
                outputSize: outputSize
            )
            contentView.cacheDisplay(in: bounds, to: bitmap)
        }

        guard let image = bitmap.cgImage,
              let pngData = bitmap.representation(
                using: .png,
                properties: [:]
              ) else {
            throw StageWindowSnapshotError.imageEncodingFailed
        }
        return StageSnapshot(image: image, pngData: pngData)
    }

    private static func makeBitmap(
        for contentView: NSView,
        bounds: CGRect,
        outputSize: StageSnapshotSize?
    ) throws -> NSBitmapImageRep {
        if let outputSize {
            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: outputSize.width,
                pixelsHigh: outputSize.height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                throw StageWindowSnapshotError.bitmapAllocationFailed
            }
            bitmap.size = bounds.size
            return bitmap
        }

        guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw StageWindowSnapshotError.bitmapAllocationFailed
        }
        return bitmap
    }

    /// Enumerates the visible Stage tiles rather than only their media children.
    /// A cropped tile deliberately hides its child while exact accepted-frame
    /// geometry is unavailable; it must still participate so export reports an
    /// incomplete source instead of silently producing a PNG with that tile
    /// missing.
    private static func visibleCroppedSourceViews(
        in root: NSView
    ) -> [CroppedSampleBufferNSView] {
        var result: [CroppedSampleBufferNSView] = []

        func visit(_ view: NSView) {
            if let sourceView = view as? CroppedSampleBufferNSView,
               !sourceView.isHiddenOrHasHiddenAncestor,
               sourceView.alphaValue > 0,
               sourceView.bounds.width > 0,
               sourceView.bounds.height > 0 {
                result.append(sourceView)
                return
            }
            for child in view.subviews {
                visit(child)
            }
        }

        visit(root)
        return result
    }
}
