import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private weak var controller: AppController?
    private weak var capture: CaptureCoordinator?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var cancellables = Set<AnyCancellable>()

    init(controller: AppController, capture: CaptureCoordinator) {
        self.controller = controller
        self.capture = capture
        super.init()

        menu.delegate = self
        statusItem.menu = menu
        updateIcon()

        capture.$isCaptureActive
            .combineLatest(capture.$statusDetail)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in self?.updateIcon() }
            .store(in: &cancellables)
        controller.$privacyCurtain
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let controller, let capture else { return }
        menu.removeAllItems()
        menu.addItem(item(
            L10n.text("ステージワークスペースを表示", "Show Stage Workspace"),
            #selector(AppController.showStageWorkspace),
            target: controller
        ))
        menu.addItem(item(
            L10n.text("共有ステージを表示", "Show Share Stage"),
            #selector(AppController.showStage),
            target: controller
        ))
        menu.addItem(.separator())
        menu.addItem(item(
            L10n.text("ソースを追加…", "Add Source…"),
            #selector(AppController.chooseSource),
            target: controller
        ))
        menu.addItem(item(
            L10n.text("アクセス権限を確認…", "Review Permissions…"),
            #selector(AppController.showPermissions),
            target: controller
        ))
        menu.addItem(item(
            "StagePane Pro…",
            #selector(AppController.showProUpgrade),
            target: controller
        ))
        menu.addItem(.separator())
        menu.addItem(item(
            L10n.text("観客向けStageの画像をコピー", "Copy Audience Stage Image"),
            #selector(AppController.copyStageScreenshot),
            target: controller
        ))
        menu.addItem(item(
            L10n.text("観客向けStageの画像を保存…", "Save Audience Stage Image…"),
            #selector(AppController.saveStageScreenshot),
            target: controller
        ))

        let curtain = item(
            L10n.text("カーテン", "Curtain"),
            #selector(AppController.toggleCurtain),
            target: controller
        )
        curtain.state = controller.privacyCurtain ? .on : .off
        menu.addItem(curtain)

        let stop = item(
            capture.hasResettableFailure
                ? L10n.text("画面取得のエラーをリセット", "Reset Capture Error")
                : L10n.stopAllAndRemoveLayersTitle,
            #selector(AppController.stopPreview),
            target: controller
        )
        stop.isEnabled = capture.hasLayers || capture.isCaptureActive || capture.hasResettableFailure
        menu.addItem(stop)
        menu.addItem(.separator())
        menu.addItem(item(
            L10n.text("StagePaneを終了", "Quit StagePane"),
            #selector(AppController.terminate),
            target: controller
        ))
    }

    private func item(_ title: String, _ action: Selector, target: AnyObject) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = target
        return item
    }

    private func updateIcon() {
        let isPreviewing = capture?.isCaptureActive == true
        let isPaused = capture.map {
            !$0.sources.isEmpty && $0.sources.allSatisfy(\.isPaused)
        } ?? false
        let isCovered = controller?.privacyCurtain == true
        let symbol = isPaused
            ? "pause.fill"
            : (isPreviewing
                ? "rectangle.inset.filled"
                : (isCovered ? "rectangle.fill.badge.xmark" : "rectangle.on.rectangle"))
        let description: String
        if isPaused && isCovered {
            description = L10n.text(
                "StagePane: すべて一時停止中・カーテン中",
                "StagePane: All sources paused — Curtain on"
            )
        } else if isPaused {
            description = L10n.text(
                "StagePane: すべて一時停止中",
                "StagePane: All sources paused"
            )
        } else if isPreviewing && isCovered {
            description = L10n.text(
                "StagePane: 画面取得中・カーテン中",
                "StagePane: Capture active — Curtain on"
            )
        } else if isPreviewing {
            description = L10n.text("StagePane: 画面取得中", "StagePane: Capture active")
        } else if isCovered {
            description = L10n.text("StagePane: カーテン中", "StagePane: Curtain on")
        } else {
            description = "StagePane"
        }
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = description
    }
}
