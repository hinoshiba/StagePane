import StagePaneCore
import SwiftUI

/// Full-height source management for the single private Workspace window.
struct WorkspaceSourcesPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 18) {
                SectionHeading(
                    eyebrow: L10n.text("SOURCES", "SOURCES"),
                    title: L10n.text("共有する内容を管理", "Manage what you share"),
                    detail: L10n.text(
                        "Appleの選択画面から1件ずつ追加し、一時停止・選び直し・解除をここで行います。",
                        "Add one item at a time with Apple’s picker, then pause, replace, or remove it here."
                    )
                )

                Spacer(minLength: 12)
                WorkspaceCaptureBadge(capture: capture, curtain: controller.privacyCurtain)
            }

            CaptureSourceList(
                controller: controller,
                capture: capture,
                showsHeading: true,
                showsWorkspaceHint: false,
                expandsSourceList: true,
                usesSecondaryAddAction: false
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: capture.sources.isEmpty ? nil : .infinity,
                alignment: .top
            )
            .cardSurface()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { sourceActions }
                VStack(alignment: .leading, spacing: 10) { sourceActions }
            }
        }
        .padding(.top, 30)
        .padding(.horizontal, 30)
        .padding(.bottom, 26)
        .frame(maxWidth: 960, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("ステージのソース管理", "Stage source management"))
    }

    @ViewBuilder
    private var sourceActions: some View {
        Button(action: controller.requestConferenceShare) {
            Label(conferenceShareTitle, systemImage: "arrow.up.forward.app")
        }
        .buttonStyle(SecondaryActionButtonStyle())

        Button(action: controller.stopPreview) {
            Label(
                capture.hasResettableFailure
                    ? L10n.text("画面取得をリセット", "Reset Capture")
                    : L10n.stopAllAndRemoveLayersTitle,
                systemImage: capture.hasResettableFailure
                    ? "arrow.counterclockwise"
                    : "stop.fill"
            )
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .disabled(
            (!capture.hasLayers && !capture.isCaptureActive && !capture.hasResettableFailure) ||
                capture.isPickerPresented
        )
    }

    private var conferenceShareTitle: String {
        if #available(macOS 15.0, *) {
            return L10n.text("共有先をStageへ切替", "Switch Active Share")
        }
        return L10n.text("共有方法を見る", "How to Share")
    }
}

/// Stage-wide output settings which are distinct from visual styling.
struct StageSettingsPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 18) {
                    SectionHeading(
                        eyebrow: L10n.text("STAGE SETTINGS", "STAGE SETTINGS"),
                        title: L10n.text("共有Stageを準備", "Prepare the Share Stage"),
                        detail: L10n.text(
                            "出力の形と公開状態を、共有用ウインドウを汚さずに整えます。",
                            "Set the output shape and audience state without putting controls in the shared window."
                        )
                    )

                    Spacer(minLength: 12)
                    WorkspaceCaptureBadge(capture: capture, curtain: controller.privacyCurtain)
                }

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text(L10n.text("ステージの形", "Stage shape"))
                            .font(.headline)
                        Spacer()
                        Text("\(controller.preset.pixelWidth) × \(controller.preset.pixelHeight)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    PresetPicker(controller: controller)
                }
                .cardSurface()

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 210), spacing: 12)],
                    spacing: 12
                ) {
                    StageSettingAction(
                        title: controller.privacyCurtain
                            ? L10n.text("カーテンを開く", "Reveal Stage")
                            : L10n.text("カーテン", "Curtain"),
                        detail: controller.privacyCurtain
                            ? L10n.text("準備できた内容を相手に表示", "Show the prepared content")
                            : L10n.text("相手側の出力をすぐ隠す", "Hide the audience output instantly"),
                        symbol: controller.privacyCurtain ? "eye.fill" : "shield.lefthalf.filled",
                        tint: controller.privacyCurtain
                            ? StagePanePalette.mintReadable
                            : StagePanePalette.coralReadable,
                        action: controller.toggleCurtain
                    )

                    StageSettingAction(
                        title: L10n.text("共有Stageを表示", "Show Share Stage"),
                        detail: L10n.text("共有用ウインドウを前面へ", "Bring the share window forward"),
                        symbol: "macwindow.on.rectangle",
                        tint: StagePanePalette.indigo,
                        action: controller.showStage
                    )

                    StageSettingAction(
                        title: capture.hasResettableFailure
                            ? L10n.text("画面取得をリセット", "Reset Capture")
                            : L10n.stopAllAndRemoveLayersTitle,
                        detail: capture.hasResettableFailure
                            ? L10n.text("エラーを消して選び直す", "Clear the error and choose again")
                            : L10n.text(
                                "全ソースの取得を終了し、レイヤーを削除",
                                "End every capture and remove its layers"
                            ),
                        symbol: capture.hasResettableFailure
                            ? "arrow.counterclockwise"
                            : "stop.fill",
                        tint: capture.hasResettableFailure ? .orange : .secondary,
                        action: controller.stopPreview,
                        isDisabled: (!capture.hasLayers &&
                            !capture.isCaptureActive &&
                            !capture.hasResettableFailure) ||
                            capture.isPickerPresented
                    )

                    StageSettingAction(
                        title: conferenceShareTitle,
                        detail: L10n.text(
                            "会議アプリで正確なStageを選択",
                            "Choose the exact Stage in your meeting app"
                        ),
                        symbol: "arrow.up.forward.app",
                        tint: StagePanePalette.aquaReadable,
                        action: controller.requestConferenceShare
                    )
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(StagePanePalette.aquaReadable)
                        .accessibilityHidden(true)
                    Text(L10n.text(
                        "Workspaceは手元用です。会議アプリでは「StagePane Stage」をウインドウ単位で共有してください。",
                        "The Workspace is private. In your meeting app, share the exact “StagePane Stage” window."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .cardSurface()
            }
            .padding(.top, 30)
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
            .frame(maxWidth: 960, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var conferenceShareTitle: String {
        if #available(macOS 15.0, *) {
            return L10n.text("共有先をStageへ切替", "Switch Active Share")
        }
        return L10n.text("共有方法を見る", "How to Share")
    }
}

private struct WorkspaceCaptureBadge: View {
    @ObservedObject var capture: CaptureCoordinator
    let curtain: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(statusTitle)
                .lineLimit(1)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(statusColor)
        .padding(.horizontal, 10)
        .frame(minHeight: 29)
        .background(statusColor.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(statusColor.opacity(0.22)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statusTitle)
        .accessibilityValue(capture.statusDetail)
    }

    private var statusTitle: String {
        if captureNeedsAttention {
            return L10n.text("確認が必要", "Needs Attention")
        }
        if allSourcesPaused {
            return L10n.text("すべて一時停止中", "All Paused")
        }
        if capture.isCaptureActive {
            return curtain
                ? L10n.text("取得中・カーテン中", "Active · Curtain On")
                : L10n.text("画面取得中", "Capture Active")
        }
        return curtain
            ? L10n.text("待機中・カーテン中", "Ready · Curtain On")
            : L10n.text("待機中", "Ready")
    }

    private var statusColor: Color {
        if captureNeedsAttention { return .orange }
        if allSourcesPaused { return .secondary }
        if capture.isCaptureActive { return StagePanePalette.mintReadable }
        return StagePanePalette.aquaReadable
    }

    private var captureNeedsAttention: Bool {
        if case .failed = capture.phase { return true }
        return false
    }

    private var allSourcesPaused: Bool {
        !capture.sources.isEmpty && capture.sources.allSatisfy(\.isPaused)
    }
}

private struct StageSettingAction: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .disabled(isDisabled)
    }
}

struct PresetPicker: View {
    @ObservedObject var controller: AppController

    var body: some View {
        HStack(spacing: 10) {
            ForEach(StagePreset.allCases) { preset in
                Button {
                    controller.setPreset(preset)
                } label: {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(
                                controller.preset == preset
                                    ? StagePanePalette.aquaReadable
                                    : Color.secondary.opacity(0.60),
                                lineWidth: controller.preset == preset ? 2 : 1
                            )
                            .aspectRatio(preset.aspectRatio, contentMode: .fit)
                            .frame(height: 34)
                        Text(L10n.presetName(preset))
                            .font(.caption2.weight(
                                controller.preset == preset ? .bold : .medium
                            ))
                            .foregroundStyle(
                                controller.preset == preset ? Color.primary : Color.secondary
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(
                                controller.preset == preset
                                    ? StagePanePalette.indigo.opacity(0.12)
                                    : Color.primary.opacity(0.035)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text(
                    "\(L10n.presetName(preset))、\(preset.pixelWidth)×\(preset.pixelHeight)",
                    "\(L10n.presetName(preset)), \(preset.pixelWidth) by \(preset.pixelHeight)"
                ))
                .accessibilityValue(
                    controller.preset == preset ? L10n.text("選択中", "Selected") : ""
                )
            }
        }
    }
}
