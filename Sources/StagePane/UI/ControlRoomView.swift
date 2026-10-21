import StagePaneCore
import SwiftUI

/// Actual Stage rendering dimensions are separate from the dimensions of an
/// explicitly exported Audience PNG and from the meeting app's resolution.
struct StageOutputDetails: View {
    @ObservedObject var controller: AppController

    var body: some View {
        DisclosureGroup(L10n.text("出力の詳細", "Output Details")) {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent(L10n.text("Stageの描画サイズ", "Stage rendering size")) {
                    Text(renderingSize)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                Button(action: controller.enlargeStageForSharing) {
                    Label(
                        L10n.text("共有向けにStageを拡大", "Enlarge Stage for Sharing"),
                        systemImage: "arrow.up.left.and.arrow.down.right"
                    )
                }
                .disabled(controller.stageIsFullScreen || controller.stageFullScreenTransitionInProgress)

                Text(L10n.text(
                    "小さいStageは共有画質が下がる場合があります。実際に共有する解像度は会議アプリが決めます。",
                    "A small Stage can reduce sharing quality. Your meeting app determines the resolution it shares."
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 10)
        }
    }

    private var renderingSize: String {
        guard let size = controller.stageRenderingSize else {
            return L10n.text("未取得", "Not available")
        }
        return "\(Int(size.width.rounded())) × \(Int(size.height.rounded())) px"
    }
}

struct StageSettingsPane: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Picker(
                    L10n.text("形", "Shape"),
                    selection: Binding(get: { controller.preset }, set: { controller.setPreset($0) })
                ) {
                    ForEach(StagePreset.allCases) { preset in
                        Text(L10n.presetName(preset)).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .disabled(controller.stageFullScreenTransitionInProgress)
                Text(L10n.text(
                    "形を変えるとStageを表示します。",
                    "Changing the shape shows Stage."
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                Picker(
                    L10n.text("背景", "Background"),
                    selection: Binding(get: { controller.theme }, set: { controller.setTheme($0) })
                ) {
                    ForEach(StageTheme.allCases) { theme in
                        Text(L10n.themeName(theme)).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }

            Divider()
            curtainSettings
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    L10n.text("セーフエリア（外周5%）", "Safe area (outer 5%)"),
                    isOn: $controller.showsSafeArea
                )
                .help(L10n.text(
                    "投影や配信で切れやすい外周5%を確認します。",
                    "Check the outer 5% that projectors and streams may crop."
                ))
                .accessibilityHint(L10n.text(
                    "投影や配信で切れやすい外周5%を確認します。",
                    "Check the outer 5% that projectors and streams may crop."
                ))
                Toggle(
                    L10n.text("StagePaneロゴを表示", "Show StagePane mark"),
                    isOn: Binding(
                        get: { controller.showsWatermark },
                        set: { controller.requestWatermarkVisibility($0) }
                    )
                )
                .accessibilityHint(controller.hasProAccess
                    ? L10n.text("Stageのロゴ表示を切り替えます。", "Toggles the StagePane mark on the Stage.")
                    : L10n.text("オフにするとStagePane Proの画面を開きます。", "Turning this off opens StagePane Pro."))
                if !controller.hasProAccess {
                    Text(L10n.text(
                        "非表示にはStagePane Proが必要です。",
                        "Hiding the mark requires StagePane Pro."
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
            }

            Divider()
            StageOutputDetails(controller: controller)
        }
    }

    private var curtainSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.text("カーテンのメッセージ", "Curtain message"))
                    .font(.body.weight(.medium))
                    .accessibilityHeading(.h2)
                Spacer()
                Text("\(controller.privacyMessage.count)/\(StageMessage.characterLimit)")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.text("メッセージの文字数", "Message character count"))
            }
            TextField(
                L10n.text("少々お待ちください", "Back in a moment"),
                text: $controller.privacyMessage,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(L10n.text("カーテンのメッセージ", "Curtain message"))
            .help(L10n.text(
                "カーテンを閉じている間だけ表示します。",
                "Shown only while the curtain is closed."
            ))
            .accessibilityHint(L10n.text(
                "カーテンを閉じている間だけ表示します。",
                "Shown only while the curtain is closed."
            ))
            Stepper(
                value: $controller.privacyMessageSize,
                in: StageMessage.textSizeRange,
                step: StageMessage.textSizeStep
            ) {
                HStack {
                    Text(L10n.text("文字の大きさ", "Text size"))
                    Spacer()
                    Text("\(controller.privacyMessageSize)%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(L10n.text("カーテンの文字の大きさ", "Curtain text size"))
            .accessibilityValue("\(controller.privacyMessageSize)%")
        }
    }
}
