import AppKit
import StagePaneCore
import SwiftUI

private let stageLayoutCanvasCoordinateSpace = "stagepane.layout.canvas"

struct StageLayoutEditor: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @FocusState private var focusedCropSourceID: StageSourceID?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                StageBackground(theme: controller.theme)

                if hasWorkspaceLayers {
                    StageCompositeDisplayView(entries: previewEntries)
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
                                    capture: capture
                                )
                            }
                        }
                    }

                    switch controller.stageInteractionMode {
                    case .arrange:
                        ForEach(capture.layout.sources) { item in
                            if let source = capture.source(for: item.id),
                               isPresented(source),
                               !source.needsReselection {
                                StageSourceEditingOverlay(
                                    source: source,
                                    frame: item.frame,
                                    canvasSize: proxy.size,
                                    controller: controller,
                                    capture: capture
                                )
                            }
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
                                controller: controller
                            )
                            .focused($focusedCropSourceID, equals: sourceID)
                        }
                    case .annotate:
                        if capture.isCaptureActive {
                            StageAnnotationInputOverlay(
                                store: controller.annotations
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

                if controller.privacyCurtain {
                    HStack(spacing: 5) {
                        Image(systemName: "shield.fill")
                        Text(L10n.text("観客側はカーテン中", "Audience curtain is on"))
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(StagePanePalette.coralReadable)
                    .padding(.horizontal, 9)
                    .frame(minHeight: 25)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                    .allowsHitTesting(false)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .coordinateSpace(name: stageLayoutCanvasCoordinateSpace)
            .clipped()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(previewAccessibilityLabel)
        .accessibilityHint(previewAccessibilityHint)
        .onAppear(perform: focusCropEditorIfNeeded)
        .onChange(of: controller.cropEditingSourceID) { _, _ in
            focusCropEditorIfNeeded()
        }
        .onChange(of: controller.stageInteractionMode) { _, _ in
            focusCropEditorIfNeeded()
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

    private var idleContent: some View {
        VStack(spacing: 15) {
            BrandMark(size: 40)

            VStack(spacing: 5) {
                Text(L10n.text("最初のStageをつくりましょう", "Build your first Stage"))
                    .font(.headline.weight(.bold))
                Text(L10n.text(
                    "選んだ内容だけを、整えて、ひとつの共有ウインドウへ。",
                    "Choose only what you need, compose it, then share one clean window."
                ))
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { emptyStageSteps }
                VStack(spacing: 6) { emptyStageSteps }
            }

            Button(action: controller.chooseSource) {
                Label(L10n.text("最初のソースを追加", "Add Your First Source"), systemImage: "plus")
                    .frame(minWidth: 154)
            }
            .buttonStyle(.borderedProminent)
            .tint(StagePanePalette.indigo)
            .disabled(!controller.canRequestSourceAddition)
            .accessibilityHint(L10n.text(
                "macOSの共有ピッカーを開きます。",
                "Opens the macOS sharing picker."
            ))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(controller.theme.prefersDarkForeground ? Color.black.opacity(0.82) : .white)
    }

    @ViewBuilder
    private var emptyStageSteps: some View {
        StageEmptyStep(
            number: 1,
            symbol: "plus.rectangle.on.rectangle",
            title: L10n.text("ソースを追加", "Add a source")
        )
        StageEmptyStep(
            number: 2,
            symbol: "crop",
            title: L10n.text("配置・切り抜き・手書き", "Arrange, crop, and draw")
        )
        StageEmptyStep(
            number: 3,
            symbol: "arrow.up.forward.app",
            title: L10n.text("Stageを共有", "Share the Stage")
        )
    }

    private var previewAccessibilityLabel: String {
        switch controller.stageInteractionMode {
        case .arrange: L10n.text("ステージ配置エディタ", "Stage layout editor")
        case .crop: L10n.text("ソース切り抜きエディタ", "Source crop editor")
        case .annotate: L10n.text("ステージ手書きキャンバス", "Stage drawing canvas")
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
            .onExitCommand(perform: controller.cancelCropEditing)
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

private struct StageEmptyStep: View {
    let number: Int
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                Text("\(number)")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 14, height: 14)
                    .background(StagePanePalette.indigo, in: Circle())
                    .offset(x: 4, y: -4)
            }

            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 42)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.text(
            "ステップ\(number)、\(title)",
            "Step \(number), \(title)"
        ))
    }
}

private struct StageAnnotationInputOverlay: View {
    @ObservedObject var store: StageAnnotationStore
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

    var body: some View {
        Button {
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

    @State private var moveStart: NormalizedStageRect?
    @State private var resizeStart: NormalizedStageRect?
    @State private var isRemoveConfirmationPresented = false

    var body: some View {
        tileContent
            .frame(width: tileWidth, height: tileHeight)
            .position(x: tileMidX, y: tileMidY)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(source.title)
            .accessibilityValue(sourcePhaseText)
            .accessibilityHint(keyboardAccessibilityHint)
            .focusable()
            .onMoveCommand(perform: handleKeyboardMove)
            .onDeleteCommand {
                guard canRequestRemoval else { return }
                isRemoveConfirmationPresented = true
            }
            .contextMenu { sourceContextMenu }
            .removeSourceConfirmation(
                isPresented: $isRemoveConfirmationPresented,
                source: source,
                controller: controller,
                capture: capture
            )
            .accessibilityAction(named: L10n.text("最前面へ", "Bring to Front")) {
                capture.bringSourceToFront(source.id)
            }
            .accessibilityAction(named: L10n.text("左へ移動", "Move Left")) {
                capture.moveSource(source.id, byX: -0.02, y: 0)
            }
            .accessibilityAction(named: L10n.text("右へ移動", "Move Right")) {
                capture.moveSource(source.id, byX: 0.02, y: 0)
            }
            .accessibilityAction(named: L10n.text("上へ移動", "Move Up")) {
                capture.moveSource(source.id, byX: 0, y: -0.02)
            }
            .accessibilityAction(named: L10n.text("下へ移動", "Move Down")) {
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
            movementSurface

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(StagePanePalette.aquaReadable, lineWidth: 2)
                .allowsHitTesting(false)

            layerHeader
            resizeHandle
        }
    }

    private var layerHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            sourceTitleBadge
            Spacer(minLength: 0)
            if tileWidth >= 96 {
                layerCropButton
            }
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
                    capture.bringSourceToFront(source.id)
                }
            )
    }

    private var sourceTitleBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: source.kind.symbolName)
            Text(source.title)
                .lineLimit(1)
            if isCropped {
                Image(systemName: "crop")
            }
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .frame(minHeight: 22)
        .background(Color.black.opacity(0.68), in: Capsule())
        .padding(6)
        .allowsHitTesting(false)
    }

    private var layerCropButton: some View {
        Button {
            controller.editCrop(of: source.id)
        } label: {
            Image(systemName: "crop")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 27, height: 27)
                .background(StagePanePalette.indigo, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.90), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .padding(5)
        .disabled(!canEditCrop)
        .help(L10n.cropLayerActionHint(source.title))
        .accessibilityLabel(L10n.cropEditAccessibilityLabel(
            source.title,
            isCropped: isCropped
        ))
        .accessibilityHint(L10n.cropLayerActionHint(source.title))
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

    @ViewBuilder
    private var sourceContextMenu: some View {
            Button(L10n.text("最前面へ", "Bring to Front")) {
                capture.bringSourceToFront(source.id)
            }
            Button(pauseActionTitle) {
                capture.togglePause(source.id)
            }
            .disabled(!capture.canTogglePause(source.id))
            Button(L10n.cropEditActionTitle(isCropped: isCropped)) {
                controller.editCrop(of: source.id)
            }
            .disabled(!canEditCrop)
            if isCropped {
                Button(L10n.cropResetActionTitle) {
                    controller.resetCrop(of: source.id)
                }
                .disabled(!canEditCrop)
            }
            Button(L10n.text("設定…", "Replace…")) {
                capture.replaceSource(source.id)
            }
            .disabled(!capture.canReplaceSource(source.id) || capture.isPickerPresented)
            Divider()
            Button(role: .destructive) {
                isRemoveConfirmationPresented = true
            } label: {
                Label(L10n.requestSourceRemovalTitle, systemImage: "exclamationmark.triangle")
            }
            .accessibilityLabel(L10n.sourceRemovalAccessibilityLabel(source.title))
            .accessibilityHint(L10n.sourceRemovalAccessibilityHint)
            .disabled(!canRequestRemoval)
    }

    private var keyboardAccessibilityHint: String {
        L10n.text(
            "矢印キーで移動、Shiftで大きく移動、Option＋矢印でサイズ変更、Deleteで解除確認を開きます。",
            "Use arrow keys to move, Shift for a larger step, Option-arrow to resize, and Delete to review removal."
        )
    }

    private var isCropped: Bool {
        controller.isSourceCropped(source.id)
    }

    private func handleKeyboardMove(_ direction: MoveCommandDirection) {
        capture.bringSourceToFront(source.id)
        if NSEvent.modifierFlags.contains(.option) {
            switch direction {
            case .left, .down: resizeBy(-0.03)
            case .right, .up: resizeBy(0.03)
            @unknown default: break
            }
            return
        }

        let step = NSEvent.modifierFlags.contains(.shift) ? 0.05 : 0.01
        switch direction {
        case .left: capture.moveSource(source.id, byX: -step, y: 0)
        case .right: capture.moveSource(source.id, byX: step, y: 0)
        case .up: capture.moveSource(source.id, byX: 0, y: -step)
        case .down: capture.moveSource(source.id, byX: 0, y: step)
        @unknown default: break
        }
    }

    private var resizeAccessibilityLabel: String {
        L10n.text(
            "\(source.title)の大きさを変更",
            "Resize \(source.title)"
        )
    }

    private var moveGesture: some Gesture {
        DragGesture(
            minimumDistance: 2,
            coordinateSpace: .named(stageLayoutCanvasCoordinateSpace)
        )
            .onChanged { value in
                if moveStart == nil {
                    moveStart = frame
                    capture.bringSourceToFront(source.id)
                }
                guard let moveStart,
                      canvasSize.width > 0,
                      canvasSize.height > 0 else { return }
                capture.setSourceFrame(
                    source.id,
                    frame: NormalizedStageRect(
                        x: moveStart.x + Double(value.translation.width / canvasSize.width),
                        y: moveStart.y + Double(value.translation.height / canvasSize.height),
                        width: moveStart.width,
                        height: moveStart.height
                    )
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
                    resizeStart = frame
                    capture.bringSourceToFront(source.id)
                }
                guard let resizeStart,
                      canvasSize.width > 0,
                      canvasSize.height > 0 else { return }
                let minimumWidth = StageLayout.defaultMinimumDimension
                let minimumHeight = StageLayout.defaultMinimumDimension
                capture.setSourceFrame(
                    source.id,
                    frame: .resized(
                        x: resizeStart.x,
                        y: resizeStart.y,
                        width: resizeStart.width + Double(value.translation.width / canvasSize.width),
                        height: resizeStart.height + Double(value.translation.height / canvasSize.height),
                        minimumWidth: minimumWidth,
                        minimumHeight: minimumHeight
                    ),
                    minimumWidth: minimumWidth,
                    minimumHeight: minimumHeight
                )
            }
            .onEnded { _ in
                resizeStart = nil
                capture.commitSourceLayout(source.id)
            }
    }

    private func resizeBy(_ delta: Double) {
        capture.setSourceFrame(
            source.id,
            frame: .resized(
                x: frame.x,
                y: frame.y,
                width: frame.width + delta,
                height: frame.height + delta,
                minimumWidth: StageLayout.defaultMinimumDimension,
                minimumHeight: StageLayout.defaultMinimumDimension
            ),
            minimumWidth: StageLayout.defaultMinimumDimension,
            minimumHeight: StageLayout.defaultMinimumDimension
        )
        capture.commitSourceLayout(source.id)
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

    private var sourcePhaseText: String {
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
            ? L10n.text("再開", "Resume")
            : L10n.text("一時停止", "Pause")
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
    var showsWorkspaceHint = true
    var expandsSourceList = false
    var usesSecondaryAddAction = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsHeading {
                HStack {
                    Text(L10n.text("ソース", "Sources"))
                        .font(.headline)
                    Spacer()
                    Text("\(capture.sources.count) / \(controller.activeSourceLimit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if controller.hasProAccess {
                        Text("PRO")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(StagePanePalette.aquaReadable)
                    }
                }
            }

            if capture.sources.isEmpty {
                Text(L10n.text(
                    "まだソースはありません。追加すると1件ずつ一覧に並びます。",
                    "No sources yet. Each item you add appears here."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(capture.sources) { source in
                            CaptureSourceRow(
                                source: source,
                                controller: controller,
                                capture: capture
                            )
                        }
                    }
                }
                .frame(maxHeight: expandsSourceList ? .infinity : 174)
            }

            if usesSecondaryAddAction {
                Button(action: controller.chooseSource) {
                    Label(addSourceTitle, systemImage: addSourceSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!controller.canRequestSourceAddition)
            } else {
                Button(action: controller.chooseSource) {
                    Label(addSourceTitle, systemImage: addSourceSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!controller.canRequestSourceAddition)
            }

            Button(action: capture.arrangeSourcesAutomatically) {
                Label(L10n.text("自動配置", "Auto Arrange"), systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(capture.sources.isEmpty || capture.isPickerPresented)

            if showsWorkspaceHint {
                Text(L10n.text(
                    "配置と手書きはキャンバスで、切り抜きは各レイヤーの切り抜きボタンから行えます。",
                    "Arrange and draw on the Canvas; crop from the crop button on each layer."
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var addSourceTitle: String {
        if StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: controller.hasProAccess
        ) {
            return L10n.text("Proで3つ目を追加", "Add a Third Source with Pro")
        }
        return L10n.text("ソースを追加", "Add Source")
    }

    private var addSourceSymbol: String {
        StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: controller.hasProAccess
        ) ? "lock.open.fill" : "plus"
    }
}

private struct CaptureSourceRow: View {
    @ObservedObject var source: CaptureSource
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @State private var isRemoveConfirmationPresented = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: source.kind.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 29, height: 29)
                .background(iconColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(phaseTitle)
                    .font(.caption2)
                    .foregroundStyle(phaseColor)
                    .lineLimit(1)
                if isCropped {
                    Label(L10n.croppedStatusTitle, systemImage: "crop")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(StagePanePalette.aquaReadable)
                        .lineLimit(1)
                }
                if isCropTarget {
                    Label(L10n.text("切り抜き編集中", "Editing crop"), systemImage: "viewfinder")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(StagePanePalette.aquaReadable)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                capture.bringSourceToFront(source.id)
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                if source.needsReselection {
                    Button {
                        capture.replaceSource(source.id)
                    } label: {
                        Image(systemName: "rectangle.badge.plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.orange)
                            .frame(width: 27, height: 27)
                            .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.reselectLayerTitle(source.title))
                    .accessibilityHint(L10n.sourceNeedsReselectionHint(source.title))
                    .help(L10n.sourceNeedsReselectionHint(source.title))
                    .disabled(!canConfigure)
                } else {
                    Button {
                        controller.editCrop(of: source.id)
                    } label: {
                        Image(systemName: "crop")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 27, height: 27)
                            .background(
                                isCropTarget
                                    ? StagePanePalette.aqua.opacity(0.22)
                                    : StagePanePalette.indigo.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 7)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.cropEditAccessibilityLabel(
                        source.title,
                        isCropped: isCropped
                    ))
                    .accessibilityHint(L10n.cropLayerActionHint(source.title))
                    .help(L10n.cropLayerActionHint(source.title))
                    .disabled(!canEditCrop)
                }

                Menu {
                    if !source.needsReselection {
                        Button(pauseActionTitle) {
                            capture.togglePause(source.id)
                        }
                        .accessibilityLabel(pauseAccessibilityLabel)
                        .disabled(!capture.canTogglePause(source.id))
                    }

                    if !source.needsReselection {
                        Button(L10n.text("選び直す", "Replace")) {
                            capture.replaceSource(source.id)
                        }
                        .accessibilityLabel(L10n.text(
                            "\(source.title)を選び直す",
                            "Replace \(source.title)"
                        ))
                        .disabled(!canConfigure)
                    }

                    if isCropped {
                        Button(L10n.cropResetActionTitle) {
                            controller.resetCrop(of: source.id)
                        }
                        .accessibilityLabel(L10n.cropResetAccessibilityLabel(source.title))
                        .accessibilityHint(L10n.cropResetAccessibilityHint)
                        .disabled(!canEditCrop)
                    }

                    Divider()

                    Button(role: .destructive) {
                        isRemoveConfirmationPresented = true
                    } label: {
                        Label(
                            L10n.requestSourceRemovalTitle,
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                    .accessibilityLabel(L10n.sourceRemovalAccessibilityLabel(source.title))
                    .accessibilityHint(L10n.sourceRemovalAccessibilityHint)
                    .disabled(!canRequestRemoval)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 25, height: 27)
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
            .controlSize(.small)
        }
        .padding(8)
        .background(
            rowBackgroundColor,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    rowBorderColor,
                    lineWidth: 1
                )
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityActions {
            Button(L10n.text("最前面へ", "Bring to Front")) {
                capture.bringSourceToFront(source.id)
            }

            if source.needsReselection {
                if canConfigure {
                    Button(L10n.reselectLayerTitle(source.title)) {
                        capture.replaceSource(source.id)
                    }
                }
            } else if canEditCrop {
                Button(L10n.cropEditAccessibilityLabel(
                    source.title,
                    isCropped: isCropped
                )) {
                    controller.editCrop(of: source.id)
                }
            }
        }
        .removeSourceConfirmation(
            isPresented: $isRemoveConfirmationPresented,
            source: source,
            controller: controller,
            capture: capture
        )
    }

    private var isStopping: Bool {
        if case .stopping = source.phase { return true }
        return false
    }

    private var canConfigure: Bool {
        !isStopping && !capture.isPickerPresented && capture.canReplaceSource(source.id)
    }

    private var canEditCrop: Bool {
        !isStopping &&
            !source.isOutputSuppressed &&
            source.isPresentationVisible &&
            !capture.isPickerPresented &&
            capture.layout[sourceID: source.id] != nil
    }

    private var isCropped: Bool {
        controller.isSourceCropped(source.id)
    }

    private var isCropTarget: Bool {
        controller.cropEditingSourceID == source.id
    }

    private var canRequestRemoval: Bool {
        capture.source(for: source.id) != nil && !isStopping && !capture.isPickerPresented
    }

    private var phaseTitle: String {
        if source.needsReselection {
            return L10n.sourceNeedsReselectionTitle
        }
        return switch source.phase {
        case .preparing: L10n.text("準備中", "Preparing")
        case .active: L10n.text("画面取得中", "Capture active")
        case .pausing: L10n.text("一時停止中…", "Pausing…")
        case .paused: L10n.text("一時停止・非表示", "Paused · Hidden")
        case .resuming: L10n.text("再開中…", "Resuming…")
        case .stopping: L10n.text("解除中…", "Removing…")
        case .needsAttention: L10n.text("確認が必要", "Needs attention")
        }
    }

    private var phaseColor: Color {
        if source.needsReselection { return .orange }
        return switch source.phase {
        case .preparing: StagePanePalette.aquaReadable
        case .active: StagePanePalette.mintReadable
        case .pausing, .paused, .resuming, .stopping: Color.secondary
        case .needsAttention: Color.orange
        }
    }

    private var iconColor: Color {
        if source.needsReselection { return .orange }
        if case .needsAttention = source.phase { return .orange }
        return StagePanePalette.indigo
    }

    private var rowBackgroundColor: Color {
        if source.needsReselection { return Color.orange.opacity(0.08) }
        if isCropTarget { return StagePanePalette.aqua.opacity(0.10) }
        return Color.primary.opacity(0.045)
    }

    private var rowBorderColor: Color {
        if source.needsReselection { return Color.orange.opacity(0.30) }
        if isCropTarget { return StagePanePalette.aqua.opacity(0.34) }
        return .clear
    }

    private var pauseActionTitle: String {
        source.isPaused
            ? L10n.text("再開", "Resume")
            : L10n.text("一時停止", "Pause")
    }

    private var pauseAccessibilityLabel: String {
        source.isPaused
            ? L10n.text("\(source.title)を再開", "Resume \(source.title)")
            : L10n.text("\(source.title)を一時停止", "Pause \(source.title)")
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
