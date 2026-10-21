import AppKit
import StagePaneCore
import SwiftUI

private let stageLayoutCanvasCoordinateSpace = "stagepane.layout.canvas"

@MainActor
private func moveLayerWithKeyboard(
    _ sourceID: StageSourceID,
    direction: MoveCommandDirection,
    capture: CaptureCoordinator
) {
    if NSEvent.modifierFlags.contains(.option) {
        let delta: Double
        switch direction {
        case .left, .down: delta = -0.03
        case .right, .up: delta = 0.03
        @unknown default: return
        }
        capture.resizeSourceContent(sourceID, byX: delta, y: delta)
        return
    }
    let step = NSEvent.modifierFlags.contains(.shift) ? 0.05 : 0.01
    switch direction {
    case .left: capture.moveSource(sourceID, byX: -step, y: 0)
    case .right: capture.moveSource(sourceID, byX: step, y: 0)
    case .up: capture.moveSource(sourceID, byX: 0, y: -step)
    case .down: capture.moveSource(sourceID, byX: 0, y: step)
    @unknown default: break
    }
}

struct StageLayoutEditor: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    var allowsEditingShortcuts = true
    @FocusState private var focusedCropSourceID: StageSourceID?
    @FocusState private var focusedArrangeSourceID: StageSourceID?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                StageBackground(theme: controller.theme)
                    .onTapGesture {
                        if controller.stageInteractionMode == .arrange {
                            controller.selectSource(nil)
                        }
                    }

                if hasWorkspaceLayers {
                    StageCompositeDisplayView(entries: previewEntries)
                        .allowsHitTesting(false)
                } else {
                    idleContent
                }

                if hasWorkspaceLayers {
                    if capture.isCaptureActive,
                       controller.stageInteractionMode != .crop {
                        StageAnnotationOverlay(store: controller.annotations)
                    }

                    if controller.stageInteractionMode != .crop {
                        ForEach(capture.layout.sources) { item in
                            if let source = capture.source(for: item.id),
                               source.needsReselection {
                                StageMissingSourceOverlay(
                                    source: source,
                                    frame: item.frame,
                                    canvasSize: proxy.size,
                                    capture: capture,
                                    beginInteraction: controller.beginWorkspaceInteraction
                                )
                            }
                        }
                    }

                    switch controller.stageInteractionMode {
                    case .arrange:
                        ForEach(capture.layout.sources) { item in
                            if let source = capture.source(for: item.id),
                               isPresented(source),
                               !source.needsReselection,
                               source.isPresentationVisible {
                                StageSourceEditingOverlay(
                                    source: source,
                                    frame: item.frame,
                                    canvasSize: proxy.size,
                                    controller: controller,
                                    capture: capture,
                                    showsSelectionControls: false,
                                    selectForEditing: { selectCanvasSource(source.id) }
                                )
                                .accessibilityHidden(true)
                            }
                        }
                        if let sourceID = controller.selectedSourceID,
                           let source = capture.source(for: sourceID),
                           let item = capture.layout[sourceID: sourceID],
                           isPresented(source), !source.needsReselection {
                            StageSourceEditingOverlay(
                                source: source,
                                frame: item.frame,
                                canvasSize: proxy.size,
                                controller: controller,
                                capture: capture,
                                showsSelectionControls: true,
                                selectForEditing: { selectCanvasSource(source.id) }
                            )
                            .focused($focusedArrangeSourceID, equals: sourceID)
                        }
                    case .crop:
                        if let sourceID = controller.cropEditingSourceID,
                           let sourceCrop = controller.cropDraft,
                           let source = capture.source(for: sourceID),
                           source.isPresentationVisible,
                           isPresented(source) {
                            StageSourceCropOverlay(
                                source: source,
                                sourceCrop: sourceCrop,
                                controller: controller,
                                allowsEditingShortcuts: allowsEditingShortcuts
                            )
                            .focused($focusedCropSourceID, equals: sourceID)
                        }
                    case .annotate:
                        if capture.isCaptureActive {
                            StageAnnotationInputOverlay(
                                store: controller.annotations,
                                beginInteraction: controller.beginWorkspaceInteraction
                            )
                        }
                    case .magnify:
                        if capture.isCaptureActive {
                            StageMagnifierPresentation(
                                store: controller.magnifier,
                                entries: previewEntries,
                                theme: controller.theme,
                                annotations: controller.annotations
                            )
                            StageMagnifierInputOverlay(
                                store: controller.magnifier,
                                beginInteraction: controller.beginWorkspaceInteraction,
                                exit: {
                                    guard allowsEditingShortcuts else { return }
                                    controller.setStageInteractionMode(.arrange)
                                }
                            )
                        }
                    }
                }

                if controller.showsWatermark,
                   controller.stageInteractionMode != .crop {
                    StageWatermark(
                        prefersDarkForeground: controller.theme.prefersDarkForeground,
                        compact: true
                    )
                }


            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .coordinateSpace(name: stageLayoutCanvasCoordinateSpace)
            .clipped()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(previewAccessibilityLabel)
        .accessibilityHint(previewAccessibilityHint)
        .onAppear {
            focusCropEditorIfNeeded()
            focusSelectedLayerIfNeeded()
        }
        .onChange(of: controller.cropEditingSourceID) { _, _ in
            focusCropEditorIfNeeded()
        }
        .onChange(of: controller.stageInteractionMode) { _, _ in
            focusCropEditorIfNeeded()
            focusSelectedLayerIfNeeded()
        }
        .onChange(of: controller.selectedSourceID) { _, sourceID in
            // Selection in the layer list must keep keyboard focus in that
            // list. Canvas gestures explicitly transfer focus for editing.
            if focusedArrangeSourceID != sourceID {
                focusedArrangeSourceID = nil
            }
        }
        .onChange(of: focusedArrangeSourceID) { _, sourceID in
            if let sourceID { controller.selectSource(sourceID) }
        }
        .onChange(of: cropEditingSourceIsVisible) { _, isVisible in
            guard controller.stageInteractionMode == .crop,
                  !isVisible else { return }
            controller.cancelCropEditing()
        }
    }

    private var previewEntries: [StageCompositeEntry] {
        if controller.stageInteractionMode == .crop {
            guard let sourceID = controller.cropEditingSourceID,
                  let source = capture.source(for: sourceID),
                  source.isPresentationVisible,
                  isPresented(source) else { return [] }
            return [
                StageCompositeEntry(
                    id: sourceID,
                    frame: .fullCanvas,
                    sourceCrop: .fullSource,
                    isVisible: source.isPresentationVisible,
                    renderer: source.previewRenderer
                )
            ]
        }

        return capture.layout.sources.compactMap { item in
            guard let source = capture.source(for: item.id),
                  isPresented(source) else { return nil }
            return StageCompositeEntry(
                id: item.id,
                frame: item.frame,
                sourceCrop: item.sourceCrop,
                isVisible: source.isPresentationVisible,
                renderer: source.previewRenderer
            )
        }
    }

    private func isPresented(_ source: CaptureSource) -> Bool {
        !source.isOutputSuppressed && source.phase != .stopping
    }

    private var cropEditingSourceIsVisible: Bool {
        guard let sourceID = controller.cropEditingSourceID,
              let source = capture.source(for: sourceID) else { return false }
        return source.isPresentationVisible
    }

    private var hasWorkspaceLayers: Bool {
        capture.layout.sources.contains { item in
            capture.source(for: item.id) != nil
        }
    }

    private func focusCropEditorIfNeeded() {
        guard controller.stageInteractionMode == .crop else {
            focusedCropSourceID = nil
            return
        }
        let sourceID = controller.cropEditingSourceID
        DispatchQueue.main.async {
            focusedCropSourceID = sourceID
        }
    }

    private func focusSelectedLayerIfNeeded() {
        focusedArrangeSourceID = controller.stageInteractionMode == .arrange
            ? controller.selectedSourceID : nil
    }

    private func selectCanvasSource(_ sourceID: StageSourceID) {
        controller.beginWorkspaceInteraction()
        controller.selectSource(sourceID)
        DispatchQueue.main.async {
            guard controller.stageInteractionMode == .arrange,
                  controller.selectedSourceID == sourceID else { return }
            focusedArrangeSourceID = sourceID
        }
    }

    private var idleContent: some View {
        Button(action: controller.chooseSource) {
            Label(L10n.text("ソースを追加…", "Add Source…"), systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)
        .tint(StagePanePalette.indigo)
        .disabled(!controller.canRequestSourceAddition)
        .accessibilityHint(L10n.text(
            "macOSの共有ピッカーを開きます。",
            "Opens the macOS sharing picker."
        ))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(controller.theme.prefersDarkForeground ? Color.black.opacity(0.82) : .white)
    }

    private var previewAccessibilityLabel: String {
        switch controller.stageInteractionMode {
        case .arrange: L10n.text("ステージ配置エディタ", "Stage layout editor")
        case .crop: L10n.text("ソース切り抜きエディタ", "Source crop editor")
        case .annotate: L10n.text("ステージ手書きキャンバス", "Stage drawing canvas")
        case .magnify: L10n.text("ステージ虫眼鏡キャンバス", "Stage magnifier canvas")
        }
    }

    private var previewAccessibilityHint: String {
        switch controller.stageInteractionMode {
        case .arrange:
            L10n.text(
                "各ソースをドラッグして移動し、右下のハンドルで大きさを変えます。",
                "Drag a source to move it and use its lower-right handle to resize it."
            )
        case .crop:
            L10n.cropEditorAccessibilityHint
        case .magnify:
            L10n.stageInteractionModeDetail(.magnify)
        case .annotate:
            if controller.annotationTool == .eraser {
                L10n.text(
                    "ドラッグして、相手に見える手書きの触れた部分を消します。",
                    "Drag to erase the parts of the audience drawing you touch."
                )
            } else {
                L10n.text(
                    "ドラッグして、相手に見えるステージへ線を描きます。",
                    "Drag to draw a line on the audience Stage."
                )
            }
        }
    }
}

private enum SourceCropCorner: CaseIterable, Hashable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

private struct StageSourceCropOverlay: View {
    @ObservedObject var source: CaptureSource
    let sourceCrop: NormalizedSourceRect
    @ObservedObject var controller: AppController
    let allowsEditingShortcuts: Bool

    @State private var moveStart: NormalizedSourceRect?
    @State private var resizeStart: NormalizedSourceRect?

    var body: some View {
        cropEditorWithSupplementalAccessibilityActions
    }

    private var cropEditorWithSupplementalAccessibilityActions: some View {
        cropEditorWithMoveAccessibilityActions
            .accessibilityAction(named: L10n.cropResetDraftTitle) {
                controller.resetCropDraft()
            }
            .accessibilityAction(named: L10n.cropExpandAction) {
                resizeAroundCenter(by: 0.05)
            }
            .accessibilityAction(named: L10n.cropTightenAction) {
                resizeAroundCenter(by: -0.05)
            }
    }

    private var cropEditorWithMoveAccessibilityActions: some View {
        accessibleCropEditor
            .accessibilityAction(named: L10n.cropMoveLeftAction) {
                moveDraft(byX: -0.01, y: 0)
            }
            .accessibilityAction(named: L10n.cropMoveRightAction) {
                moveDraft(byX: 0.01, y: 0)
            }
            .accessibilityAction(named: L10n.cropMoveUpAction) {
                moveDraft(byX: 0, y: -0.01)
            }
            .accessibilityAction(named: L10n.cropMoveDownAction) {
                moveDraft(byX: 0, y: 0.01)
            }
    }

    private var accessibleCropEditor: some View {
        interactiveCropEditor
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.cropEditorAccessibilityLabel(source.title))
            .accessibilityValue(cropAccessibilityValue)
            .accessibilityHint(L10n.cropEditorAccessibilityHint)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: resizeAroundCenter(by: 0.05)
                case .decrement: resizeAroundCenter(by: -0.05)
                @unknown default: break
                }
            }
    }

    private var interactiveCropEditor: some View {
        cropGeometry
            .contentShape(Rectangle())
            .focusable()
            .onMoveCommand(perform: handleKeyboardMove)
            .onExitCommand {
                guard allowsEditingShortcuts else { return }
                controller.cancelCropEditing()
            }
            .contextMenu {
                Button {
                    controller.resetCropDraft()
                } label: {
                    Label(
                        L10n.cropResetDraftTitle,
                        systemImage: "arrow.counterclockwise"
                    )
                }
                .disabled(sourceCrop == .fullSource)
            }
    }

    private var cropGeometry: some View {
        GeometryReader { proxy in
            cropGeometryContent(tileSize: proxy.size)
        }
    }

    @ViewBuilder
    private func cropGeometryContent(tileSize: CGSize) -> some View {
        if let fullSourceFrame = SourceCropProjection.sourceFrame(
            sourceSize: source.contentSize,
            sourceCrop: .fullSource,
            destinationSize: tileSize
        ), let selectionFrame = SourceCropProjection.selectionFrame(
            sourceSize: source.contentSize,
            sourceCrop: sourceCrop,
            destinationSize: tileSize
        ) {
            cropGeometryContent(
                fullSourceFrame: fullSourceFrame,
                selectionFrame: selectionFrame,
                tileSize: tileSize
            )
        }
    }

    private func cropGeometryContent(
        fullSourceFrame: CGRect,
        selectionFrame: CGRect,
        tileSize: CGSize
    ) -> some View {
        ZStack(alignment: .topLeading) {
            cropShade(
                fullSourceFrame: fullSourceFrame,
                selectionFrame: selectionFrame
            )
            selectionSurface(
                selectionFrame: selectionFrame,
                fullSourceFrame: fullSourceFrame
            )
            selectionOutline(selectionFrame: selectionFrame)
            cropHandles(
                selectionFrame: selectionFrame,
                fullSourceFrame: fullSourceFrame,
                tileSize: tileSize
            )
            sourceBadge
                .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func selectionOutline(selectionFrame: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .stroke(StagePanePalette.aquaReadable, lineWidth: 2)
            .frame(
                width: selectionFrame.width,
                height: selectionFrame.height
            )
            .position(
                x: selectionFrame.midX,
                y: selectionFrame.midY
            )
            .allowsHitTesting(false)
    }

    private func cropHandles(
        selectionFrame: CGRect,
        fullSourceFrame: CGRect,
        tileSize: CGSize
    ) -> some View {
        ForEach(SourceCropCorner.allCases, id: \.self) { corner in
            cropHandle(corner)
                .position(handlePosition(
                    corner,
                    selectionFrame: selectionFrame,
                    tileSize: tileSize
                ))
                .highPriorityGesture(resizeGesture(
                    corner: corner,
                    fullSourceFrame: fullSourceFrame
                ))
        }
    }

    private func cropShade(
        fullSourceFrame: CGRect,
        selectionFrame: CGRect
    ) -> some View {
        Path { path in
            path.addRect(fullSourceFrame)
            path.addRect(selectionFrame)
        }
        .fill(
            Color.black.opacity(0.62),
            style: FillStyle(eoFill: true)
        )
        .allowsHitTesting(false)
    }

    private func selectionSurface(
        selectionFrame: CGRect,
        fullSourceFrame: CGRect
    ) -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .frame(
                width: selectionFrame.width,
                height: selectionFrame.height
            )
            .position(
                x: selectionFrame.midX,
                y: selectionFrame.midY
            )
            .gesture(moveGesture(fullSourceFrame: fullSourceFrame))
    }

    private func cropHandle(_ corner: SourceCropCorner) -> some View {
        Circle()
            .fill(StagePanePalette.indigo)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.95), lineWidth: 1.5)
            }
            .frame(width: 18, height: 18)
            .shadow(color: .black.opacity(0.48), radius: 3, y: 1)
            .contentShape(Circle().inset(by: -6))
            .accessibilityHidden(true)
    }

    private var sourceBadge: some View {
        Label(source.title, systemImage: "crop")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .frame(minHeight: 22)
            .background(Color.black.opacity(0.72), in: Capsule())
            .padding(.top, 6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func moveGesture(fullSourceFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if moveStart == nil {
                    moveStart = sourceCrop
                }
                guard let moveStart,
                      fullSourceFrame.width > 0,
                      fullSourceFrame.height > 0 else { return }
                controller.setCropDraft(
                    moveStart.moved(
                        byX: Double(value.translation.width / fullSourceFrame.width),
                        y: Double(value.translation.height / fullSourceFrame.height)
                    ),
                    for: source.id
                )
            }
            .onEnded { _ in
                moveStart = nil
            }
    }

    private func resizeGesture(
        corner: SourceCropCorner,
        fullSourceFrame: CGRect
    ) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if resizeStart == nil {
                    resizeStart = sourceCropWithEditorMinimum(sourceCrop)
                }
                guard let resizeStart,
                      fullSourceFrame.width > 0,
                      fullSourceFrame.height > 0 else { return }
                let deltaX = Double(value.translation.width / fullSourceFrame.width)
                let deltaY = Double(value.translation.height / fullSourceFrame.height)
                controller.setCropDraft(
                    resizedCrop(
                        resizeStart,
                        moving: corner,
                        byX: deltaX,
                        y: deltaY
                    ),
                    for: source.id
                )
            }
            .onEnded { _ in
                resizeStart = nil
            }
    }

    private func resizedCrop(
        _ start: NormalizedSourceRect,
        moving corner: SourceCropCorner,
        byX deltaX: Double,
        y deltaY: Double
    ) -> NormalizedSourceRect {
        let minimum = StageLayout.defaultMinimumSourceCropDimension
        let left = start.x
        let top = start.y
        let right = start.x + start.width
        let bottom = start.y + start.height

        switch corner {
        case .topLeft:
            let newLeft = min(max(left + deltaX, 0), right - minimum)
            let newTop = min(max(top + deltaY, 0), bottom - minimum)
            return cropRect(
                left: newLeft,
                top: newTop,
                right: right,
                bottom: bottom
            )
        case .topRight:
            let newRight = min(max(right + deltaX, left + minimum), 1)
            let newTop = min(max(top + deltaY, 0), bottom - minimum)
            return cropRect(
                left: left,
                top: newTop,
                right: newRight,
                bottom: bottom
            )
        case .bottomLeft:
            let newLeft = min(max(left + deltaX, 0), right - minimum)
            let newBottom = min(max(bottom + deltaY, top + minimum), 1)
            return cropRect(
                left: newLeft,
                top: top,
                right: right,
                bottom: newBottom
            )
        case .bottomRight:
            let newRight = min(max(right + deltaX, left + minimum), 1)
            let newBottom = min(max(bottom + deltaY, top + minimum), 1)
            return cropRect(
                left: left,
                top: top,
                right: newRight,
                bottom: newBottom
            )
        }
    }

    private func cropRect(
        left: Double,
        top: Double,
        right: Double,
        bottom: Double
    ) -> NormalizedSourceRect {
        NormalizedSourceRect(
            x: left,
            y: top,
            width: right - left,
            height: bottom - top,
            minimumWidth: StageLayout.defaultMinimumSourceCropDimension,
            minimumHeight: StageLayout.defaultMinimumSourceCropDimension
        )
    }

    private func sourceCropWithEditorMinimum(
        _ crop: NormalizedSourceRect
    ) -> NormalizedSourceRect {
        NormalizedSourceRect(
            x: crop.x,
            y: crop.y,
            width: crop.width,
            height: crop.height,
            minimumWidth: StageLayout.defaultMinimumSourceCropDimension,
            minimumHeight: StageLayout.defaultMinimumSourceCropDimension
        )
    }

    private func handleKeyboardMove(_ direction: MoveCommandDirection) {
        if NSEvent.modifierFlags.contains(.option) {
            switch direction {
            case .left, .down: resizeAroundCenter(by: -0.03)
            case .right, .up: resizeAroundCenter(by: 0.03)
            @unknown default: break
            }
            return
        }

        let step = NSEvent.modifierFlags.contains(.shift) ? 0.05 : 0.01
        switch direction {
        case .left: moveDraft(byX: -step, y: 0)
        case .right: moveDraft(byX: step, y: 0)
        case .up: moveDraft(byX: 0, y: -step)
        case .down: moveDraft(byX: 0, y: step)
        @unknown default: return
        }
    }

    private func moveDraft(byX deltaX: Double, y deltaY: Double) {
        controller.setCropDraft(
            sourceCrop.moved(byX: deltaX, y: deltaY),
            for: source.id
        )
    }

    private func resizeAroundCenter(by delta: Double) {
        let minimum = StageLayout.defaultMinimumSourceCropDimension
        let width = min(max(sourceCrop.width + delta, minimum), 1)
        let height = min(max(sourceCrop.height + delta, minimum), 1)
        let centerX = sourceCrop.x + sourceCrop.width / 2
        let centerY = sourceCrop.y + sourceCrop.height / 2
        let x = min(max(centerX - width / 2, 0), 1 - width)
        let y = min(max(centerY - height / 2, 0), 1 - height)
        controller.setCropDraft(
            NormalizedSourceRect(
                x: x,
                y: y,
                width: width,
                height: height,
                minimumWidth: minimum,
                minimumHeight: minimum
            ),
            for: source.id
        )
    }

    private func handlePosition(
        _ corner: SourceCropCorner,
        selectionFrame: CGRect,
        tileSize: CGSize
    ) -> CGPoint {
        let x: CGFloat
        let y: CGFloat
        switch corner {
        case .topLeft:
            x = selectionFrame.minX
            y = selectionFrame.minY
        case .topRight:
            x = selectionFrame.maxX
            y = selectionFrame.minY
        case .bottomLeft:
            x = selectionFrame.minX
            y = selectionFrame.maxY
        case .bottomRight:
            x = selectionFrame.maxX
            y = selectionFrame.maxY
        }
        return CGPoint(
            x: min(max(x, 9), max(9, tileSize.width - 9)),
            y: min(max(y, 9), max(9, tileSize.height - 9))
        )
    }

    private var cropAccessibilityValue: String {
        L10n.cropAccessibilityValue(
            left: Int((sourceCrop.x * 100).rounded()),
            top: Int((sourceCrop.y * 100).rounded()),
            width: Int((sourceCrop.width * 100).rounded()),
            height: Int((sourceCrop.height * 100).rounded())
        )
    }
}

private struct StageAnnotationInputOverlay: View {
    @ObservedObject var store: StageAnnotationStore
    let beginInteraction: () -> Void
    @State private var isDrawing = false
    @State private var pointerLocation: CGPoint?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                pointerLocation = value.location
                                if !isDrawing {
                                    beginInteraction()
                                    isDrawing = store.beginStroke(
                                        at: value.location,
                                        canvasSize: proxy.size
                                    )
                                } else {
                                    store.appendPoint(
                                        at: value.location,
                                        canvasSize: proxy.size
                                    )
                                }
                            }
                            .onEnded { value in
                                pointerLocation = value.location
                                store.appendPoint(
                                    at: value.location,
                                    canvasSize: proxy.size
                                )
                                store.endStroke()
                                isDrawing = false
                            }
                    )

                if store.preferences.tool == .eraser,
                   let pointerLocation {
                    eraserCursor(in: proxy.size)
                        .position(pointerLocation)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                if store.isEraserAtCapacity {
                    Label(
                        L10n.text(
                            "操作上限です。取り消すか、すべて消してください。",
                            "Action limit reached. Undo or clear the drawing."
                        ),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 28)
                    .background(Color.black.opacity(0.76), in: Capsule())
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .allowsHitTesting(false)
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case let .active(location):
                    pointerLocation = location
                case .ended:
                    pointerLocation = nil
                }
            }
        }
        .onDisappear {
            store.endStroke()
            isDrawing = false
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text("手書きキャンバス", "Drawing canvas"))
        .accessibilityHint(canvasAccessibilityHint)
    }

    private func eraserCursor(in canvasSize: CGSize) -> some View {
        let diameter = max(
            2,
            min(canvasSize.width, canvasSize.height) *
                CGFloat(store.preferences.eraserNormalizedWidth)
        )
        return Circle()
            .fill(Color.black.opacity(0.20))
            .overlay {
                Circle()
                    .strokeBorder(
                        Color.white.opacity(0.92),
                        lineWidth: min(1.5, diameter / 3)
                    )
            }
            .overlay {
                if diameter >= 15 {
                    Image(systemName: "eraser.fill")
                        .font(.system(
                            size: min(11, diameter * 0.46),
                            weight: .semibold
                        ))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
    }

    private var canvasAccessibilityHint: String {
        if store.preferences.tool == .eraser {
            return L10n.text(
                "ポインタでドラッグして、触れた部分を消します。コマンドZで元に戻せます。",
                "Drag to erase the parts you touch. Press Command-Z to undo."
            )
        }
        return L10n.text(
            "ポインタでドラッグして線を描きます。取り消しと全消去は上のボタンを使います。",
            "Drag with the pointer to draw. Use the buttons above to undo or clear."
        )
    }
}

/// A logical layer whose picker-approved capture session has ended.
///
/// The public Stage receives no renderer for this layer. The private Workspace
/// keeps this placeholder at the retained layout frame so reconnecting the
/// source is explicit and cannot be mistaken for adding a new layer.
private struct StageMissingSourceOverlay: View {
    @ObservedObject var source: CaptureSource
    let frame: NormalizedStageRect
    let canvasSize: CGSize
    @ObservedObject var capture: CaptureCoordinator
    let beginInteraction: () -> Void

    var body: some View {
        Button {
            beginInteraction()
            capture.replaceSource(source.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.42))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                Color.orange.opacity(0.76),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                            )
                    }

                ViewThatFits(in: .vertical) {
                    VStack(spacing: 6) {
                        Image(systemName: "rectangle.badge.plus")
                            .font(.system(size: 20, weight: .semibold))
                        Text(source.title)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                        Text(L10n.sourceNeedsReselectionTitle)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }

                    Label(source.title, systemImage: "rectangle.badge.plus")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.orange)
                .padding(9)
            }
        }
        .buttonStyle(.plain)
        .frame(width: tileWidth, height: tileHeight)
        .position(x: tileMidX, y: tileMidY)
        .disabled(!capture.canReplaceSource(source.id))
        .help(L10n.sourceNeedsReselectionHint(source.title))
        .accessibilityLabel(L10n.reselectLayerTitle(source.title))
        .accessibilityValue(L10n.sourceNeedsReselectionTitle)
        .accessibilityHint(L10n.sourceNeedsReselectionHint(source.title))
    }

    private var tileWidth: CGFloat {
        canvasSize.width * CGFloat(frame.width)
    }

    private var tileHeight: CGFloat {
        canvasSize.height * CGFloat(frame.height)
    }

    private var tileMidX: CGFloat {
        canvasSize.width * CGFloat(frame.x + frame.width / 2)
    }

    private var tileMidY: CGFloat {
        canvasSize.height * CGFloat(frame.y + frame.height / 2)
    }
}

private struct StageSourceEditingOverlay: View {
    @ObservedObject var source: CaptureSource
    let frame: NormalizedStageRect
    let canvasSize: CGSize
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    let showsSelectionControls: Bool
    let selectForEditing: () -> Void

    @State private var moveStart: NormalizedStageRect?
    @State private var resizeStart: NormalizedStageRect?
    @State private var isRemoveConfirmationPresented = false

    var body: some View {
        tileContent
            .frame(width: tileWidth, height: tileHeight)
            .focusable(showsSelectionControls)
            // The moving outline provides focus feedback for this backing.
            // Keep the controls outside this modifier's subtree so buttons
            // retain their own native keyboard focus effects.
            .focusEffectDisabled()
            .overlay(alignment: .topLeading) {
                if showsSelectionControls {
                    ZStack(alignment: .topLeading) {
                        layerHeader
                        resizeHandle
                    }
                }
            }
            .position(x: tileMidX, y: tileMidY)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(source.title)
            .accessibilityValue("\(L10n.text("選択中", "Selected")), \(sourcePhaseText)")
            .accessibilityHint(keyboardAccessibilityHint)
            .onExitCommand { controller.selectSource(nil) }
            .onMoveCommand(perform: handleKeyboardMove)
            .onKeyPress(.space) {
                guard capture.canTogglePause(source.id) else { return .ignored }
                controller.beginWorkspaceInteraction()
                capture.togglePause(source.id)
                return .handled
            }
            .onDeleteCommand {
                guard canRequestRemoval else { return }
                isRemoveConfirmationPresented = true
            }
            .removeSourceConfirmation(
                isPresented: $isRemoveConfirmationPresented,
                source: source,
                controller: controller,
                capture: capture
            )
            .accessibilityAction(named: L10n.text("最前面へ", "Bring to Front")) {
                controller.beginWorkspaceInteraction()
                capture.bringSourceToFront(source.id)
            }
            .accessibilityAction(named: L10n.text("左へ移動", "Move Left")) {
                controller.beginWorkspaceInteraction()
                capture.moveSource(source.id, byX: -0.02, y: 0)
            }
            .accessibilityAction(named: L10n.text("右へ移動", "Move Right")) {
                controller.beginWorkspaceInteraction()
                capture.moveSource(source.id, byX: 0.02, y: 0)
            }
            .accessibilityAction(named: L10n.text("上へ移動", "Move Up")) {
                controller.beginWorkspaceInteraction()
                capture.moveSource(source.id, byX: 0, y: -0.02)
            }
            .accessibilityAction(named: L10n.text("下へ移動", "Move Down")) {
                controller.beginWorkspaceInteraction()
                capture.moveSource(source.id, byX: 0, y: 0.02)
            }
            .accessibilityAction(named: L10n.text("大きくする", "Make Larger")) {
                resizeBy(0.05)
            }
            .accessibilityAction(named: L10n.text("小さくする", "Make Smaller")) {
                resizeBy(-0.05)
            }
            .accessibilityAction(named: L10n.cropEditAccessibilityLabel(
                source.title,
                isCropped: isCropped
            )) {
                guard canEditCrop else { return }
                controller.editCrop(of: source.id)
            }
            .accessibilityAction(named: L10n.sourceRemovalAccessibilityLabel(source.title)) {
                guard canRequestRemoval else { return }
                isRemoveConfirmationPresented = true
            }
    }

    private var tileContent: some View {
        ZStack(alignment: .topLeading) {
            if showsSelectionControls {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(
                        StagePanePalette.aquaReadable,
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: source.isPresentationVisible ? [] : [6, 4]
                        )
                    )
                    .allowsHitTesting(false)
            } else {
                movementSurface
            }
        }
    }

    private var layerHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            sourceTitleBadge
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var movementSurface: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(moveGesture)
            .simultaneousGesture(
                TapGesture().onEnded {
                    selectForEditing()
                }
            )
            .contextMenu { sourceContextMenu }
    }

    private var sourceTitleBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: source.kind.symbolName)
            Text(source.title)
                .lineLimit(1)
            if isCropped {
                Image(systemName: "crop")
            }
            if capture.layout[sourceID: source.id]?.isColorInverted == true {
                Image(systemName: "circle.lefthalf.filled")
                    .accessibilityLabel(L10n.layerColorsInvertedStatus)
            }
            if !source.isPresentationVisible {
                Image(systemName: "eye.slash")
                Text(L10n.text("非表示", "Hidden"))
            }
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .frame(minHeight: 22)
        .background(Color.black.opacity(0.68), in: Capsule())
        .padding(6)
        .contentShape(Rectangle())
        .gesture(moveGesture)
        .contextMenu { sourceContextMenu }
        .help(L10n.text(
            "このラベルをドラッグすると、重なったレイヤーも順序を変えずに移動できます。",
            "Drag this label to move an overlapping layer without changing its stacking order."
        ))
    }

    private var resizeHandle: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 25, height: 25)
                    .background(StagePanePalette.indigo, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1))
                    .padding(5)
                    .contentShape(Circle())
                    .highPriorityGesture(resizeGesture)
                    .accessibilityLabel(resizeAccessibilityLabel)
            }
        }
    }

    private var sourceContextMenu: some View {
        SourceLayerMenu(
            source: source,
            controller: controller,
            capture: capture,
            requestRemoval: { isRemoveConfirmationPresented = true }
        )
    }

    private var keyboardAccessibilityHint: String {
        L10n.text(
            "選択しても重なり順は変わりません。矢印キーで移動、Shiftで大きく移動、Option＋矢印でサイズ変更、Spaceで非表示・再表示、Deleteで解除確認を開きます。",
            "Selection preserves stacking order. Use arrows to move, Shift for a larger step, Option-arrow to resize, Space to hide or show, and Delete to review removal."
        )
    }

    private var isCropped: Bool {
        controller.isSourceCropped(source.id)
    }

    private func handleKeyboardMove(_ direction: MoveCommandDirection) {
        controller.beginWorkspaceInteraction()
        controller.selectSource(source.id)
        moveLayerWithKeyboard(source.id, direction: direction, capture: capture)
    }

    private var resizeAccessibilityLabel: String {
        L10n.text(
            "\(source.title)の縦横比を保って大きさを変更",
            "Resize \(source.title) proportionally"
        )
    }

    private var moveGesture: some Gesture {
        DragGesture(
            minimumDistance: 2,
            coordinateSpace: .named(stageLayoutCanvasCoordinateSpace)
        )
            .onChanged { value in
                if moveStart == nil {
                    moveStart = contentFrame
                    selectForEditing()
                }
                guard let moveStart,
                      canvasSize.width > 0,
                      canvasSize.height > 0 else { return }
                capture.setSourceFrame(
                    source.id,
                    frame: moveStart.moved(
                        byX: Double(value.translation.width / canvasSize.width),
                        y: Double(value.translation.height / canvasSize.height)
                    ),
                    minimumWidth: 0,
                    minimumHeight: 0
                )
            }
            .onEnded { _ in moveStart = nil }
    }

    private var resizeGesture: some Gesture {
        DragGesture(
            minimumDistance: 1,
            coordinateSpace: .named(stageLayoutCanvasCoordinateSpace)
        )
            .onChanged { value in
                if resizeStart == nil {
                    resizeStart = contentFrame
                    selectForEditing()
                }
                guard let resizeStart,
                      canvasSize.width > 0,
                      canvasSize.height > 0 else { return }
                guard let resizedFrame = StageContentGeometry.resizedFrame(
                    resizeStart,
                    translation: value.translation,
                    canvasSize: canvasSize
                ) else { return }
                capture.setSourceFrame(
                    source.id,
                    frame: resizedFrame,
                    minimumWidth: 0,
                    minimumHeight: 0
                )
            }
            .onEnded { _ in
                resizeStart = nil
                capture.commitSourceLayout(source.id)
            }
    }

    private func resizeBy(_ delta: Double) {
        controller.beginWorkspaceInteraction()
        capture.resizeSourceContent(source.id, byX: delta, y: delta)
    }

    private var contentFrame: NormalizedStageRect {
        capture.sourceContentFrame(source.id, canvasSize: canvasSize) ?? frame
    }

    private var tileWidth: CGFloat {
        canvasSize.width * CGFloat(contentFrame.width)
    }

    private var tileHeight: CGFloat {
        canvasSize.height * CGFloat(contentFrame.height)
    }

    private var tileMidX: CGFloat {
        canvasSize.width * CGFloat(contentFrame.x + contentFrame.width / 2)
    }

    private var tileMidY: CGFloat {
        canvasSize.height * CGFloat(contentFrame.y + contentFrame.height / 2)
    }

    private var sourcePhaseText: String {
        if let summary = capture.attentionSummary(for: source.id) { return summary }
        return switch source.phase {
        case .preparing: L10n.text("準備中", "Preparing")
        case .active: L10n.text("画面取得中", "Capture active")
        case .pausing: L10n.text("一時停止中", "Pausing")
        case .paused: L10n.text("一時停止・非表示", "Paused · Hidden")
        case .resuming: L10n.text("再開中", "Resuming")
        case .stopping: L10n.text("解除中", "Removing")
        case .needsAttention: L10n.text("確認が必要", "Needs attention")
        }
    }

    private var pauseActionTitle: String {
        source.isPaused
            ? L10n.text("再表示", "Show")
            : L10n.text("非表示", "Hide")
    }

    private var canRequestRemoval: Bool {
        guard capture.source(for: source.id) != nil,
              !capture.isPickerPresented else { return false }
        if case .stopping = source.phase { return false }
        return true
    }

    private var canEditCrop: Bool {
        canRequestRemoval &&
            !source.isOutputSuppressed &&
            source.isPresentationVisible &&
            capture.layout[sourceID: source.id] != nil
    }
}

struct CaptureSourceList: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    var showsHeading = true
    var expandsSourceList = false
    var usesSecondaryAddAction = false
    @FocusState private var focusedSourceID: StageSourceID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsHeading {
                HStack {
                    Text(L10n.text("レイヤー", "Layers"))
                        .font(.headline)
                    Spacer()
                    Text("\(capture.sources.count) / \(controller.activeSourceLimitDescription)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(
                            controller.sourceCountAccessibilityDescription(capture.sources.count)
                        )
                }
            }

            if !capture.sources.isEmpty {
                LayerReorderList(
                    sourceIDs: capture.layout.sources.reversed().map(\.id),
                    focusedSourceID: focusedSourceID,
                    canMove: canReorderSource,
                    move: { offsets, destination, expectedIDs in
                        guard !offsets.isEmpty,
                              offsets.allSatisfy({ expectedIDs.indices.contains($0) && canReorderSource(expectedIDs[$0]) }) else { return }
                        controller.beginWorkspaceInteraction()
                        capture.moveSources(
                            fromFrontOffsets: offsets,
                            toFrontOffset: destination,
                            expectedFrontToBackIDs: expectedIDs
                        )
                    }
                ) { sourceID in
                    if let source = capture.source(for: sourceID) {
                        CaptureSourceRow(
                            source: source,
                            controller: controller,
                            capture: capture,
                            focusedSourceID: $focusedSourceID,
                            canReorder: canReorderSource(sourceID),
                            moveSelection: { direction in
                                selectAdjacentSource(to: source.id, direction: direction)
                            }
                        )
                    }
                }
                .frame(maxHeight: expandsSourceList ? .infinity : 174)
            }

            if !expandsSourceList {
                sourceAdditionButton
                Button {
                    controller.beginWorkspaceInteraction()
                    capture.arrangeSourcesAutomatically()
                } label: {
                    Label(L10n.text("自動配置", "Auto Arrange"), systemImage: "square.grid.2x2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(capture.sources.isEmpty || capture.isPickerPresented || controller.stageInteractionMode == .crop)

            }
        }
    }

    private func canReorderSource(_ sourceID: StageSourceID) -> Bool {
        guard controller.stageInteractionMode != .crop,
              !capture.isPickerPresented,
              capture.layout.sources.count > 1,
              capture.layout[sourceID: sourceID] != nil,
              let source = capture.source(for: sourceID) else { return false }
        return source.phase != .stopping
    }

    @ViewBuilder
    private var sourceAdditionButton: some View {
        if usesSecondaryAddAction {
            Button(action: controller.chooseSource) { sourceAdditionLabel }
                .buttonStyle(SecondaryActionButtonStyle())
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!controller.canRequestSourceAddition)
                .accessibilityHint(addSourceAccessibilityHint)
        } else {
            Button(action: controller.chooseSource) { sourceAdditionLabel }
                .buttonStyle(PrimaryActionButtonStyle())
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!controller.canRequestSourceAddition)
                .accessibilityHint(addSourceAccessibilityHint)
        }
    }

    private var sourceAdditionLabel: some View {
        Label(
            requiresProForSourceAddition
                ? L10n.text("Proでさらに追加", "Add More with Pro")
                : L10n.text("ソースを追加", "Add Source"),
            systemImage: requiresProForSourceAddition ? "lock.open.fill" : "plus"
        )
        .frame(maxWidth: .infinity)
    }

    private var addSourceAccessibilityHint: String {
        requiresProForSourceAddition
            ? L10n.text("StagePane Proの購入画面を開きます。", "Opens the StagePane Pro purchase screen.")
            : L10n.text("Appleの共有内容選択画面を開きます。", "Opens Apple’s content-sharing picker.")
    }

    private var requiresProForSourceAddition: Bool {
        StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: controller.hasProAccess
        )
    }

    private func selectAdjacentSource(to sourceID: StageSourceID, direction: MoveCommandDirection) {
        let sources = capture.layout.sources.reversed().compactMap { item in
            capture.source(for: item.id)
        }.filter { $0.phase != .stopping }
        guard let index = sources.firstIndex(where: { $0.id == sourceID }) else { return }
        let nextIndex: Int
        switch direction {
        case .up: nextIndex = max(0, index - 1)
        case .down: nextIndex = min(sources.count - 1, index + 1)
        default: return
        }
        let nextID = sources[nextIndex].id
        controller.selectSource(nextID)
        focusedSourceID = nextID
    }
}

private struct CaptureSourceRow: View {
    @ObservedObject var source: CaptureSource
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    var focusedSourceID: FocusState<StageSourceID?>.Binding
    let canReorder: Bool
    let moveSelection: (MoveCommandDirection) -> Void
    @State private var isRemoveConfirmationPresented = false
    @State private var showsErrorDetails = false
    @State private var isRenamePresented = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundStyle(canReorder ? Color.secondary : Color.secondary.opacity(0.4))
                .frame(width: 16, height: 44)
                .contentShape(Rectangle())
                .help(canReorder
                    ? L10n.text("ドラッグで並べ替えます。上のレイヤーほど手前に表示します。", "Drag to reorder. Layers at the top appear in front.")
                    : L10n.text("切り抜きやソース選択を終えると、複数のレイヤーを並べ替えられます。", "Finish cropping or source selection to reorder multiple layers."))
                .accessibilityHidden(true)
            Button {
                controller.selectSource(source.id)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: source.kind.symbolName)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(source.title)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                .lineLimit(1)
                            if isColorInverted {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .help(L10n.layerColorsInvertedStatus)
                                    .accessibilityHidden(true)
                            }
                        }
                        if source.phase != .active || capture.attentionSummary(for: source.id) != nil {
                            Text(phaseTitle)
                                .font(.system(size: 12))
                                .lineLimit(2)
                                .foregroundStyle(needsAttention ? Color.orange : Color.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .focused(focusedSourceID, equals: source.id)
            .disabled(source.phase == .stopping)
            .help(errorMessage ?? source.title)
            .accessibilityLabel(L10n.text("\(source.title)を選択", "Select \(source.title)"))
            .accessibilityValue([
                isSelected ? L10n.text("選択中", "Selected") : "",
                phaseTitle,
                isColorInverted ? L10n.layerColorsInvertedStatus : ""
            ]
                .filter { !$0.isEmpty }.joined(separator: ", "))
            .accessibilityHint(L10n.text(
                "上下キーで選択します。ドラッグ、またはその他の操作メニューで重なり順を変更できます。上のレイヤーほど手前です。キャンバス上では矢印キーで配置を調整します。選択だけでは重なり順は変わりません。",
                "Use Up and Down to select. Drag or use the actions menu to change stacking order. Top layers appear in front. Arrow keys on the canvas adjust placement. Selection alone preserves stacking order."
            ))
            .onMoveCommand(perform: moveSelection)

            visibilityControl

            Menu {
                rowActions
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(L10n.text(
                "\(source.title)レイヤーのその他の操作",
                "More actions for the \(source.title) layer"
            ))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
        .background(isSelected ? Color.accentColor.opacity(0.13) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: L10n.renameLayerActionTitle, beginRenaming)
        .contextMenu { rowActions }
        .sheet(isPresented: $isRenamePresented) {
            RenameLayerSheet(source: source, capture: capture)
        }
        .removeSourceConfirmation(
            isPresented: $isRemoveConfirmationPresented,
            source: source,
            controller: controller,
            capture: capture
        )
        .popover(isPresented: $showsErrorDetails) {
            VStack(alignment: .leading, spacing: 12) {
                Text(source.title).font(.headline)
                Text(errorMessage ?? phaseTitle).textSelection(.enabled)
                Button(L10n.text("閉じる", "Close")) { showsErrorDetails = false }
            }
            .padding(18)
            .frame(width: 320)
        }
    }

    @ViewBuilder
    private var rowActions: some View {
        Button(action: beginRenaming) {
            Label(L10n.renameLayerActionTitle, systemImage: "pencil")
        }
        .disabled(!canRename)
        Divider()
        SourceLayerMenu(
            source: source,
            controller: controller,
            capture: capture,
            requestRemoval: { isRemoveConfirmationPresented = true }
        )
        if errorMessage != nil {
            Divider()
            Button(L10n.text("問題の詳細…", "Issue Details…")) { showsErrorDetails = true }
        }
    }

    private var canRename: Bool {
        source.phase != .stopping && !capture.isPickerPresented && capture.source(for: source.id) != nil
    }

    private func beginRenaming() {
        guard canRename else { return }
        controller.beginWorkspaceInteraction()
        isRenamePresented = true
    }

    @ViewBuilder
    private var visibilityControl: some View {
        if source.needsReselection {
            Button {
                controller.beginWorkspaceInteraction()
                capture.replaceSource(source.id)
            } label: {
                Text(L10n.text("選び直す", "Select Again"))
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 28, minHeight: 28)
            .accessibilityLabel(L10n.reselectLayerTitle(source.title))
            .help(L10n.sourceNeedsReselectionHint(source.title))
            .disabled(!capture.canReplaceSource(source.id) || capture.isPickerPresented)
        } else {
            Button {
                controller.beginWorkspaceInteraction()
                capture.togglePause(source.id)
            } label: {
                Image(systemName: source.isPaused ? "eye.slash" : "eye")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(source.isPaused
                ? L10n.text("\(source.title)を再表示", "Show \(source.title)")
                : L10n.text("\(source.title)を非表示", "Hide \(source.title)"))
            .accessibilityValue(phaseTitle)
            .help(source.isPaused
                ? L10n.text("新しい映像を受信して再表示します。", "Resume capture and show a fresh frame.")
                : L10n.text("取得を一時停止し、位置と切り抜きを保持します。", "Pause capture, keeping placement and crop."))
            .disabled(!capture.canTogglePause(source.id))
        }
    }

    private var isSelected: Bool { controller.selectedSourceID == source.id }
    private var isColorInverted: Bool { capture.layout[sourceID: source.id]?.isColorInverted ?? false }
    private var needsAttention: Bool { if case .needsAttention = source.phase { return true }; return false }
    private var errorMessage: String? { if case let .needsAttention(message) = source.phase { return message }; return nil }
    private var phaseTitle: String {
        if let summary = capture.attentionSummary(for: source.id) { return summary }
        if source.needsReselection { return L10n.text("選び直しが必要", "Select again") }
        switch source.phase {
        case .preparing: return L10n.text("映像を準備中", "Preparing video")
        case .active: return L10n.text("画面取得中", "Capturing")
        case .pausing: return L10n.text("非表示にしています…", "Hiding…")
        case .paused: return L10n.text("非表示・取得停止", "Hidden · Capture paused")
        case .resuming: return L10n.text("再表示の準備中…", "Preparing to show…")
        case .stopping: return L10n.text("解除中…", "Removing…")
        case .needsAttention: return L10n.text("確認が必要", "Needs attention")
        }
    }
}

/// Controls in the stable area outside the canvas, bound to one selected layer.
struct SelectedLayerTools: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        if let sourceID = controller.selectedSourceID,
           let source = capture.source(for: sourceID) {
            SelectedSourceTools(source: source, controller: controller, capture: capture)
                .id(source.id)
        }
    }
}

private struct SelectedSourceTools: View {
    @ObservedObject var source: CaptureSource
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @State private var isRemoveConfirmationPresented = false

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)

            SourceColorInversionToggle(source: source, controller: controller, capture: capture)
                .toggleStyle(.switch)
                .fixedSize()

            Button {
                controller.editCrop(of: source.id)
            } label: {
                Label(L10n.cropEditActionTitle(isCropped: controller.isSourceCropped(source.id)), systemImage: "crop")
            }
            .disabled(!canEditCrop)
            .accessibilityLabel(L10n.cropEditAccessibilityLabel(source.title, isCropped: controller.isSourceCropped(source.id)))
            .help(L10n.cropLayerActionHint(source.title))

            Menu {
                SourceLayerMenu(source: source, controller: controller, capture: capture,
                                requestRemoval: { isRemoveConfirmationPresented = true })
            } label: {
                Image(systemName: "ellipsis").frame(minWidth: 20)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .accessibilityLabel(L10n.text("\(source.title)のその他の操作", "More actions for \(source.title)"))
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("\(source.title)の操作", "Actions for \(source.title)"))
        .removeSourceConfirmation(isPresented: $isRemoveConfirmationPresented,
                                  source: source, controller: controller, capture: capture)
    }

    private var canEditCrop: Bool {
        source.phase != .stopping && !source.isOutputSuppressed && source.isPresentationVisible &&
            !capture.isPickerPresented && capture.layout[sourceID: source.id] != nil
    }
}

/// Shared by the layer row, fixed selected-layer tools, and canvas context menu.
private struct SourceLayerMenu: View {
    @ObservedObject var source: CaptureSource
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    let requestRemoval: () -> Void

    var body: some View {
        Button(L10n.text("ひとつ前面へ", "Move Forward")) {
            controller.beginWorkspaceInteraction()
            capture.bringSourceForward(source.id)
        }
        .disabled(!canReorder || capture.layout.sources.last?.id == source.id)
        Button(L10n.text("ひとつ背面へ", "Move Backward")) {
            controller.beginWorkspaceInteraction()
            capture.sendSourceBackward(source.id)
        }
        .disabled(!canReorder || capture.layout.sources.first?.id == source.id)
        Button(L10n.text("最前面へ", "Bring to Front")) {
            controller.beginWorkspaceInteraction()
            capture.bringSourceToFront(source.id)
        }
        .disabled(!canReorder || capture.layout.sources.last?.id == source.id)
        Button(L10n.text("最背面へ", "Send to Back")) {
            controller.beginWorkspaceInteraction()
            capture.sendSourceToBack(source.id)
        }
        .disabled(!canReorder || capture.layout.sources.first?.id == source.id)
        Divider()
        Button(source.isPaused ? L10n.text("再表示", "Show") : L10n.text("非表示", "Hide")) {
            controller.beginWorkspaceInteraction()
            capture.togglePause(source.id)
        }
        .disabled(!capture.canTogglePause(source.id))
        Button(L10n.cropEditActionTitle(isCropped: controller.isSourceCropped(source.id))) {
            controller.editCrop(of: source.id)
        }
        .disabled(!canEditCrop)
        if controller.isSourceCropped(source.id) {
            Button(L10n.cropResetActionTitle) {
                controller.beginWorkspaceInteraction()
                controller.resetCrop(of: source.id)
            }
            .disabled(!canEditCrop)
        }
        SourceColorInversionToggle(source: source, controller: controller, capture: capture)
        Button(L10n.text("選び直す…", "Replace…")) {
            controller.beginWorkspaceInteraction()
            capture.replaceSource(source.id)
        }
        .disabled(!capture.canReplaceSource(source.id) || capture.isPickerPresented || source.phase == .stopping)
        Divider()
        Button(role: .destructive, action: requestRemoval) {
            Label(L10n.requestSourceRemovalTitle, systemImage: "trash")
        }
        .accessibilityLabel(L10n.sourceRemovalAccessibilityLabel(source.title))
        .accessibilityHint(L10n.sourceRemovalAccessibilityHint)
        .disabled(source.phase == .stopping || capture.isPickerPresented)
    }

    private var canReorder: Bool {
        source.phase != .stopping && !capture.isPickerPresented && controller.stageInteractionMode != .crop
    }
    private var canEditCrop: Bool {
        source.phase != .stopping && !source.isOutputSuppressed && source.isPresentationVisible &&
            !capture.isPickerPresented && capture.layout[sourceID: source.id] != nil
    }
}

private struct SourceColorInversionToggle: View {
    @ObservedObject var source: CaptureSource
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        Toggle(isOn: colorInversionBinding) {
            Label(L10n.invertLayerColorsTitle, systemImage: "circle.lefthalf.filled")
        }
        .disabled(!canInvertColors)
        .accessibilityLabel(L10n.invertLayerColorsAccessibilityLabel(source.title))
        .accessibilityHint(L10n.invertLayerColorsHint)
        .help(L10n.invertLayerColorsHint)
    }

    private var colorInversionBinding: Binding<Bool> {
        Binding(
            get: { capture.layout[sourceID: source.id]?.isColorInverted ?? false },
            set: { isInverted in
                guard canInvertColors else { return }
                controller.beginWorkspaceInteraction()
                capture.setSourceColorInverted(source.id, isInverted: isInverted)
            }
        )
    }

    private var canInvertColors: Bool {
        source.phase != .stopping && !capture.isPickerPresented &&
            capture.layout[sourceID: source.id] != nil
    }
}

@MainActor
private struct RenameLayerSheet: View {
    @ObservedObject var source: CaptureSource
    @ObservedObject var capture: CaptureCoordinator
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool
    @State private var nameDraft: String

    init(source: CaptureSource, capture: CaptureCoordinator) {
        self.source = source
        self.capture = capture
        _nameDraft = State(initialValue: source.customName ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.renameLayerTitle)
                .font(.headline)
            Text(L10n.renameLayerHint(defaultTitle: source.defaultTitle))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.layerNameTitle)
                    .font(.callout)
                TextField(L10n.layerNameTitle, text: $nameDraft, prompt: Text(source.defaultTitle))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.layerNameTitle)
                    .focused($isNameFocused)
                    .onSubmit(save)
            }
            HStack {
                Spacer()
                Button(L10n.text("キャンセル", "Cancel"), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.text("保存", "Save"), action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear { isNameFocused = true }
    }

    private var canSave: Bool {
        source.phase != .stopping && !capture.isPickerPresented && capture.source(for: source.id) != nil
    }

    private func save() {
        guard canSave else { return }
        capture.renameSource(source.id, to: nameDraft)
        dismiss()
    }
}

private struct RemoveSourceConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @ObservedObject var source: CaptureSource
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    func body(content: Content) -> some View {
        content.confirmationDialog(
            L10n.sourceRemovalConfirmationTitle(source.title),
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button(L10n.confirmSourceRemovalTitle, role: .destructive) {
                confirmRemoval()
            }
            .disabled(!canConfirmRemoval)

            Button(L10n.cancelSourceRemovalTitle, role: .cancel) {}
        } message: {
            Text(source.needsReselection
                ? L10n.detachedLayerRemovalConfirmationMessage
                : L10n.sourceRemovalConfirmationMessage)
        }
    }

    private var canConfirmRemoval: Bool {
        guard capture.source(for: source.id) != nil,
              !capture.isPickerPresented else { return false }
        if case .stopping = source.phase { return false }
        return true
    }

    private func confirmRemoval() {
        guard canConfirmRemoval else {
            isPresented = false
            return
        }
        let sourceTitle = source.title
        controller.removeSource(source.id) { error in
            controller.transientNotice = error ?? L10n.sourceRemovedNotice(sourceTitle)
        }
    }
}

private extension View {
    func removeSourceConfirmation(
        isPresented: Binding<Bool>,
        source: CaptureSource,
        controller: AppController,
        capture: CaptureCoordinator
    ) -> some View {
        modifier(RemoveSourceConfirmationModifier(
            isPresented: isPresented,
            source: source,
            controller: controller,
            capture: capture
        ))
    }
}
