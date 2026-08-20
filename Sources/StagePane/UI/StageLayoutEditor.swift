import AppKit
import StagePaneCore
import SwiftUI

private let stageLayoutCanvasCoordinateSpace = "stagepane.layout.canvas"

struct StageLayoutEditor: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                StageBackground(theme: controller.theme)

                if capture.isCaptureActive {
                    StageCompositeDisplayView(entries: previewEntries)
                } else {
                    idleContent
                }

                if capture.isCaptureActive {
                    StageAnnotationOverlay(store: controller.annotations)

                    switch controller.stageInteractionMode {
                    case .arrange:
                        ForEach(capture.layout.sources) { item in
                            if let source = capture.source(for: item.id),
                               isPresented(source) {
                                StageSourceEditingOverlay(
                                    source: source,
                                    frame: item.frame,
                                    canvasSize: proxy.size,
                                    controller: controller,
                                    capture: capture
                                )
                            }
                        }
                    case .control:
                        ForEach(capture.layout.sources) { item in
                            if let source = capture.source(for: item.id),
                               isPresented(source) {
                                StageSourceControlOverlay(
                                    source: source,
                                    frame: item.frame,
                                    canvasSize: proxy.size,
                                    controller: controller
                                )
                            }
                        }
                    case .annotate:
                        StageAnnotationInputOverlay(
                            store: controller.annotations
                        )
                    }
                }

                if controller.showsWatermark {
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
    }

    private var previewEntries: [StageCompositeEntry] {
        capture.layout.sources.compactMap { item in
            guard let source = capture.source(for: item.id),
                  isPresented(source) else { return nil }
            return StageCompositeEntry(
                id: item.id,
                frame: item.frame,
                renderer: source.previewRenderer
            )
        }
    }

    private func isPresented(_ source: CaptureSource) -> Bool {
        !source.isOutputSuppressed && source.phase != .stopping
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
            .disabled(!capture.canAddSource)
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
            symbol: "rectangle.3.group",
            title: L10n.text("配置・手書き", "Arrange and draw")
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
        case .control: L10n.text("ステージボタン操作プレビュー", "Stage button-action preview")
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
        case .control:
            L10n.text(
                "ウインドウソース内で、アクセシビリティのPressに対応するボタンだけを操作できます。",
                "Only buttons that expose a supported Accessibility Press action inside a window source can be used."
            )
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

private struct StageSourceControlOverlay: View {
    @ObservedObject var source: CaptureSource
    let frame: NormalizedStageRect
    let canvasSize: CGSize
    @ObservedObject var controller: AppController

    @ViewBuilder
    var body: some View {
        if canPerformButtonAction {
            controlSurface
                .accessibilityAction {
                    controller.forwardPreviewClick(
                        at: CGPoint(x: tileMidX, y: tileMidY),
                        stageSize: canvasSize,
                        expectedSourceID: source.id
                    )
                }
        } else {
            controlSurface
                .accessibilityRespondsToUserInteraction(false)
        }
    }

    private var controlSurface: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture(
                        coordinateSpace: .named(stageLayoutCanvasCoordinateSpace)
                    )
                    .onEnded { value in
                        guard canPerformButtonAction else { return }
                        controller.forwardPreviewClick(
                            at: value.location,
                            stageSize: canvasSize,
                            expectedSourceID: source.id
                        )
                    }
                )

            capabilityBadge
        }
        .frame(width: tileWidth, height: tileHeight)
        .position(x: tileMidX, y: tileMidY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(
            "\(source.title)のボタン操作",
            "Button actions for \(source.title)"
        ))
        .accessibilityValue(capabilityTitle)
        .accessibilityHint(capabilityAccessibilityHint)
    }

    private var capabilityBadge: some View {
        Label(capabilityTitle, systemImage: capabilitySymbol)
            .font(.system(size: 9, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(capabilityColor)
            .padding(.horizontal, 7)
            .frame(minHeight: 21)
            .background(Color.black.opacity(0.74), in: Capsule())
            .overlay {
                Capsule().stroke(capabilityColor.opacity(0.52), lineWidth: 1)
            }
            .padding(6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var canPerformButtonAction: Bool {
        source.kind == .window && !source.isPaused
    }

    private var capabilityTitle: String {
        if source.isPaused {
            return L10n.text("一時停止中", "Paused")
        }
        guard source.kind == .window else {
            return L10n.text("表示のみ", "View only")
        }
        return L10n.text("対応ボタン", "Supported buttons")
    }

    private var capabilitySymbol: String {
        if source.isPaused { return "pause.fill" }
        return source.kind == .window ? "hand.tap.fill" : "eye.fill"
    }

    private var capabilityColor: Color {
        if source.isPaused { return StagePanePalette.coralReadable }
        return source.kind == .window
            ? StagePanePalette.mintReadable
            : Color.white.opacity(0.72)
    }

    private var capabilityAccessibilityHint: String {
        if source.isPaused {
            return L10n.text(
                "ソースを再開すると、対応ボタンだけを操作できます。",
                "Resume the source to use supported button actions."
            )
        }
        guard source.kind == .window else {
            return L10n.text(
                "このソースは表示専用です。ボタン操作には、1つのウインドウとして追加してください。",
                "This source is view only. Add one specific window to use supported button actions."
            )
        }
        return L10n.text(
            "アクセシビリティのPressに対応するボタンだけを操作します。一般的な画面領域、キー入力、ドラッグには対応しません。",
            "Only buttons that expose an Accessibility Press action are supported. General content, keyboard input, and drags are not."
        )
    }

    private var tileWidth: CGFloat { canvasSize.width * CGFloat(frame.width) }
    private var tileHeight: CGFloat { canvasSize.height * CGFloat(frame.height) }
    private var tileMidX: CGFloat {
        canvasSize.width * CGFloat(frame.x + frame.width / 2)
    }
    private var tileMidY: CGFloat {
        canvasSize.height * CGFloat(frame.y + frame.height / 2)
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

            sourceTitleBadge
            resizeHandle
        }
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
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .frame(minHeight: 22)
        .background(Color.black.opacity(0.68), in: Capsule())
        .padding(6)
        .allowsHitTesting(false)
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
        switch source.phase {
        case .preparing: L10n.text("準備中", "Preparing")
        case .active: L10n.text("画面取得中", "Capture active")
        case .pausing: L10n.text("一時停止中", "Pausing")
        case .paused: L10n.text("一時停止", "Paused")
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
                    Text("\(capture.sources.count) / \(CaptureCoordinator.maximumSources)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
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
                    Label(L10n.text("ソースを追加", "Add Source"), systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!capture.canAddSource)
            } else {
                Button(action: controller.chooseSource) {
                    Label(L10n.text("ソースを追加", "Add Source"), systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!capture.canAddSource)
            }

            Button(action: capture.arrangeSourcesAutomatically) {
                Label(L10n.text("自動配置", "Auto Arrange"), systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(capture.sources.isEmpty || capture.isPickerPresented)

            if showsWorkspaceHint {
                Text(AppController.supportsControlMode
                    ? L10n.text(
                        "配置・操作・手書きは、大きなステージワークスペースで行えます。",
                        "Arrange, control, and draw in the large Stage Workspace."
                    )
                    : L10n.text(
                        "配置・手書きは、大きなステージワークスペースで行えます。",
                        "Arrange and draw in the large Stage Workspace."
                    ))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
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
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Button(pauseActionTitle) {
                    capture.togglePause(source.id)
                }
                .accessibilityLabel(pauseAccessibilityLabel)
                .disabled(!capture.canTogglePause(source.id))

                Button(L10n.text("選び直す", "Replace")) {
                    capture.replaceSource(source.id)
                }
                .accessibilityLabel(L10n.text(
                    "\(source.title)を選び直す",
                    "Replace \(source.title)"
                ))
                .disabled(!canConfigure)

                Button(role: .destructive) {
                    isRemoveConfirmationPresented = true
                } label: {
                    Label(L10n.requestSourceRemovalTitle, systemImage: "exclamationmark.triangle")
                }
                .accessibilityLabel(L10n.sourceRemovalAccessibilityLabel(source.title))
                .accessibilityHint(L10n.sourceRemovalAccessibilityHint)
                .help(L10n.sourceRemovalAccessibilityHint)
                .disabled(!canRequestRemoval)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            capture.bringSourceToFront(source.id)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: L10n.text("最前面へ", "Bring to Front")) {
            capture.bringSourceToFront(source.id)
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

    private var canRequestRemoval: Bool {
        capture.source(for: source.id) != nil && !isStopping && !capture.isPickerPresented
    }

    private var phaseTitle: String {
        switch source.phase {
        case .preparing: L10n.text("準備中", "Preparing")
        case .active: L10n.text("画面取得中", "Capture active")
        case .pausing: L10n.text("一時停止中…", "Pausing…")
        case .paused: L10n.text("一時停止", "Paused")
        case .resuming: L10n.text("再開中…", "Resuming…")
        case .stopping: L10n.text("解除中…", "Removing…")
        case .needsAttention: L10n.text("確認が必要", "Needs attention")
        }
    }

    private var phaseColor: Color {
        switch source.phase {
        case .preparing: StagePanePalette.aquaReadable
        case .active: StagePanePalette.mintReadable
        case .pausing, .paused, .resuming, .stopping: Color.secondary
        case .needsAttention: Color.orange
        }
    }

    private var iconColor: Color {
        if case .needsAttention = source.phase { return .orange }
        return StagePanePalette.indigo
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
            Text(L10n.sourceRemovalConfirmationMessage)
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
