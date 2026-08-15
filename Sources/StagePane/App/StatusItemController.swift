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
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateIcon() }
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
            L10n.text("コントロールルームを表示", "Show Control Room"),
            #selector(AppController.showControlRoom),
            target: controller
        ))
        menu.addItem(item(
            L10n.text("共有ステージを表示", "Show Share Stage"),
            #selector(AppController.showStage),
            target: controller
        ))
        menu.addItem(.separator())
        menu.addItem(item(
            L10n.text("ソースを選択…", "Choose Source…"),
            #selector(AppController.chooseSource),
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
            L10n.text("プレビューを停止", "Stop Preview"),
            #selector(AppController.stopPreview),
            target: controller
        )
        stop.isEnabled = capture.isCaptureActive
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
        let isCovered = controller?.privacyCurtain == true
        let symbol = isPreviewing ? "rectangle.inset.filled" : (isCovered ? "rectangle.fill.badge.xmark" : "rectangle.on.rectangle")
        let description: String
        if isPreviewing && isCovered {
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
