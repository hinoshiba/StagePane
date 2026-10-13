import StagePaneCore
import SwiftUI

struct StageMagnifierPresentation: View {
    @ObservedObject var store: StageMagnifierStore
    let entries: [StageCompositeEntry]
    let theme: StageTheme
    let annotations: StageAnnotationStore

    var body: some View {
        StageMagnifierOverlay(
            entries: entries,
            theme: theme,
            annotations: annotations,
            position: store.position,
            magnification: store.magnification
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct StageMagnifierInputOverlay: View {
    @ObservedObject var store: StageMagnifierStore
    let exit: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle())
                .focusable()
                .focusEffectDisabled()
                .focused($isFocused)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        store.move(to: location, in: proxy.size)
                    case .ended:
                        store.hide()
                    }
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isFocused = true
                        store.move(to: value.location, in: proxy.size)
                    }
                    .onEnded { value in
                        store.move(to: value.location, in: proxy.size)
                    }
                )
                .onMoveCommand { direction in
                    let step: CGFloat = NSEvent.modifierFlags.contains(.shift) ? 0.05 : 0.01
                    switch direction {
                    case .left: store.move(byX: -step, y: 0)
                    case .right: store.move(byX: step, y: 0)
                    case .up: store.move(byX: 0, y: -step)
                    case .down: store.move(byX: 0, y: step)
                    @unknown default: break
                    }
                }
                .onExitCommand(perform: exit)
                .accessibilityLabel(L10n.text("虫眼鏡の位置", "Magnifier position"))
                .accessibilityHint(L10n.text(
                    "カーソルまたは矢印キーで拡大する位置を移動します。Escで配置に戻ります。",
                    "Move the pointer or use arrow keys to move the lens. Press Esc to return to Arrange."
                ))
                .accessibilityValue(accessibilityPosition)
                .accessibilityAction(named: L10n.text("中央に表示", "Show at Center")) {
                    store.center()
                }
                .onAppear { isFocused = true }
                .onChange(of: store.focusRequest) { _, _ in isFocused = true }
                .onDisappear { store.hide() }
        }
    }

    private var accessibilityPosition: String {
        guard let position = store.position else {
            return L10n.text("非表示", "Hidden")
        }
        return L10n.text(
            "左から\(Int(position.x * 100))%、上から\(Int(position.y * 100))%",
            "\(Int(position.x * 100)) percent from left, \(Int(position.y * 100)) percent from top"
        )
    }
}
