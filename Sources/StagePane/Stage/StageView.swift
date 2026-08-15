import StagePaneCore
import SwiftUI

struct StageView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ZStack {
            StageBackground(theme: controller.theme)

            if capture.isCaptureActive && !controller.privacyCurtain {
                SampleBufferDisplayView(renderer: capture.renderer)
                    .background(Color.black)
                    .transition(.opacity)
                    .accessibilityLabel(L10n.text("共有ステージのプレビュー", "Share stage preview"))
            } else if controller.privacyCurtain {
                curtain
                    .transition(.opacity)
            } else {
                idleStage
                    .transition(.opacity)
            }

            if controller.showsSafeArea {
                safeAreaOverlay
                    .allowsHitTesting(false)
            }

            if controller.showsWatermark {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 7) {
                            BrandMark(size: 20)
                            Text("StagePane")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(controller.theme.prefersDarkForeground ? Color.black.opacity(0.64) : Color.white.opacity(0.72))
                        .padding(16)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .frame(minWidth: 480, minHeight: 270)
        .clipped()
        .animation(
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .easeOut(duration: 0.16),
            value: controller.privacyCurtain
        )
        .accessibilityElement(children: .contain)
    }

    private var curtain: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 360 || proxy.size.width < 620
            VStack(spacing: compact ? 10 : 18) {
                ZStack {
                    Circle()
                        .fill(foreground.opacity(0.10))
                        .frame(width: compact ? 56 : 78, height: compact ? 56 : 78)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: compact ? 24 : 32, weight: .semibold))
                        .foregroundStyle(foreground)
                }
                Text(controller.privacyMessage)
                    .font(.system(size: compact ? 24 : 30, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(foreground)
                    .lineLimit(compact ? 3 : 4)
                    .minimumScaleFactor(0.50)
                    .allowsTightening(true)
                    .padding(.horizontal, compact ? 24 : 44)
                Text(L10n.text("共有内容を隠しています", "Stage content is hidden"))
                    .font(compact ? .caption.weight(.medium) : .subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(foreground.opacity(0.72))
                    .lineLimit(2)
            }
            .padding(compact ? 16 : 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.text("カーテン中。共有内容を隠しています。", "Curtain on. Stage content is hidden."))
        .accessibilityValue(controller.privacyMessage)
        .accessibilityHint(capture.isCaptureActive
            ? L10n.text(
                "画面取得は動作中です。完全に止めるにはコントロールルームを使います。",
                "Capture remains active. Use Control Room to stop it completely."
            )
            : "")
    }

    private var idleStage: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 360 || proxy.size.width < 620
            VStack(spacing: compact ? 12 : 20) {
                BrandMark(size: compact ? 48 : 72)
                VStack(spacing: compact ? 4 : 7) {
                    Text(L10n.text("共有ステージの準備ができました", "Your share stage is ready"))
                        .font(.system(size: compact ? 21 : 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(foreground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.70)
                    Text(L10n.text(
                        "コントロールルームでソースを選ぶか、このまま待機画面として共有できます。",
                        "Choose a source in Control Room, or share this as a clean holding screen."
                    ))
                    .font(compact ? .caption : .subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(foreground.opacity(0.74))
                    .lineLimit(compact ? 3 : 4)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: 520)
                }
            }
            .padding(compact ? 20 : 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.text("共有ステージの準備ができました", "Your share stage is ready"))
        .accessibilityHint(L10n.text(
            "コントロールルームでソースを選ぶか、このまま待機画面として共有できます。",
            "Choose a source in Control Room, or share this as a clean holding screen."
        ))
    }

    private var safeAreaOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        foreground.opacity(0.36),
                        style: StrokeStyle(lineWidth: 1, dash: [7, 6])
                    )
                    .padding(proxy.size.width * 0.05)
                Text(L10n.text("セーフエリア", "SAFE AREA"))
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(foreground.opacity(0.52))
                    .padding(.horizontal, 8)
                    .background(controller.theme.prefersDarkForeground ? Color.white.opacity(0.75) : Color.black.opacity(0.42))
                    .offset(y: -proxy.size.height * 0.45)
            }
        }
        .accessibilityHidden(true)
    }

    private var foreground: Color {
        controller.theme.prefersDarkForeground ? Color.black.opacity(0.82) : Color.white
    }
}
