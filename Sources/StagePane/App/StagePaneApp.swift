import AppKit
import SwiftUI

@main
struct StagePaneApplication: App {
    @NSApplicationDelegateAdaptor(StagePaneAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class StagePaneAppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController?
    private var terminationReplyPending = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let controller = AppController()
        self.controller = controller
        NSApp.mainMenu = makeMainMenu(controller: controller)

        if let snapshotDirectory = snapshotDirectoryArgument() {
            controller.start(showWindows: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                do {
                    try controller.writeSnapshots(to: snapshotDirectory)
                    print("Snapshots written to \(snapshotDirectory.path)")
                    NSApp.terminate(nil)
                } catch {
                    fputs("Snapshot failed: \(error)\n", stderr)
                    exit(1)
                }
            }
        } else {
            controller.start()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag { controller?.showControlRoom() }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let capture = controller?.capture, capture.isCaptureActive else {
            return .terminateNow
        }
        guard !terminationReplyPending else { return .terminateLater }

        terminationReplyPending = true
        capture.stop { [weak self, weak sender] _ in
            guard let self, self.terminationReplyPending else { return }
            self.terminationReplyPending = false
            // A failed ScreenCaptureKit stop remains truthfully marked active
            // until this point. Process termination itself then releases the
            // remaining stream, so quitting is never trapped by a system error.
            sender?.reply(toApplicationShouldTerminate: true)
        }
        // A framework callback must not be able to trap Quit forever. Process
        // termination is the final capture teardown if ScreenCaptureKit itself
        // fails to deliver a completion.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self, weak sender] in
            guard let self, self.terminationReplyPending else { return }
            self.terminationReplyPending = false
            sender?.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    private func makeMainMenu(controller: AppController) -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "StagePane")
        appMenu.addItem(
            withTitle: L10n.text("StagePaneについて", "About StagePane"),
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(menuItem(
            L10n.text("設定…", "Settings…"),
            action: #selector(AppController.showControlRoom),
            key: ",",
            modifiers: [.command],
            target: controller
        ))
        appMenu.addItem(.separator())

        let servicesItem = NSMenuItem(title: L10n.text("サービス", "Services"), action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: L10n.text("サービス", "Services"))
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(.separator())

        appMenu.addItem(menuItem(
            L10n.text("StagePaneを隠す", "Hide StagePane"),
            action: #selector(NSApplication.hide(_:)),
            key: "h",
            modifiers: [.command],
            target: NSApp
        ))
        appMenu.addItem(menuItem(
            L10n.text("ほかを隠す", "Hide Others"),
            action: #selector(NSApplication.hideOtherApplications(_:)),
            key: "h",
            modifiers: [.command, .option],
            target: NSApp
        ))
        appMenu.addItem(menuItem(
            L10n.text("すべてを表示", "Show All"),
            action: #selector(NSApplication.unhideAllApplications(_:)),
            key: "",
            modifiers: [],
            target: NSApp
        ))
        appMenu.addItem(.separator())
        let quit = NSMenuItem(
            title: L10n.text("StagePaneを終了", "Quit StagePane"),
            action: #selector(AppController.terminate),
            keyEquivalent: "q"
        )
        quit.target = controller
        appMenu.addItem(quit)
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: L10n.text("編集", "Edit"))
        editMenu.addItem(menuItem(
            L10n.text("取り消す", "Undo"),
            action: Selector(("undo:")),
            key: "z",
            modifiers: [.command]
        ))
        editMenu.addItem(menuItem(
            L10n.text("やり直す", "Redo"),
            action: Selector(("redo:")),
            key: "z",
            modifiers: [.command, .shift]
        ))
        editMenu.addItem(.separator())
        editMenu.addItem(menuItem(L10n.text("カット", "Cut"), action: #selector(NSText.cut(_:)), key: "x", modifiers: [.command]))
        editMenu.addItem(menuItem(L10n.text("コピー", "Copy"), action: #selector(NSText.copy(_:)), key: "c", modifiers: [.command]))
        editMenu.addItem(menuItem(L10n.text("ペースト", "Paste"), action: #selector(NSText.paste(_:)), key: "v", modifiers: [.command]))
        editMenu.addItem(menuItem(L10n.text("すべてを選択", "Select All"), action: #selector(NSText.selectAll(_:)), key: "a", modifiers: [.command]))
        editItem.submenu = editMenu
        main.addItem(editItem)

        let stageItem = NSMenuItem()
        let stageMenu = NSMenu(title: L10n.text("ステージ", "Stage"))
        stageMenu.addItem(menuItem(
            L10n.text("共有ステージを表示", "Show Share Stage"),
            action: #selector(AppController.showStage),
            key: "s",
            modifiers: [.command, .shift],
            target: controller
        ))
        stageMenu.addItem(menuItem(
            L10n.text("ソースを選択…", "Choose Source…"),
            action: #selector(AppController.chooseSource),
            key: "p",
            modifiers: [.command, .shift],
            target: controller
        ))
        stageMenu.addItem(menuItem(
            L10n.text("カーテンを切り替え", "Toggle Curtain"),
            action: #selector(AppController.toggleCurtain),
            key: "h",
            modifiers: [.command, .shift],
            target: controller
        ))
        stageMenu.addItem(menuItem(
            L10n.text("プレビューを停止", "Stop Preview"),
            action: #selector(AppController.stopPreview),
            key: ".",
            modifiers: [.command],
            target: controller
        ))
        stageItem.submenu = stageMenu
        main.addItem(stageItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: L10n.text("ウインドウ", "Window"))
        windowMenu.addItem(menuItem(
            L10n.text("しまう", "Minimize"),
            action: #selector(NSWindow.performMiniaturize(_:)),
            key: "m",
            modifiers: [.command]
        ))
        windowMenu.addItem(menuItem(
            L10n.text("拡大／縮小", "Zoom"),
            action: #selector(NSWindow.performZoom(_:)),
            key: "",
            modifiers: []
        ))
        windowMenu.addItem(.separator())
        windowMenu.addItem(menuItem(
            L10n.text("コントロールルーム", "Control Room"),
            action: #selector(AppController.showControlRoom),
            key: "0",
            modifiers: [.command],
            target: controller
        ))
        windowMenu.addItem(menuItem(
            L10n.text("すべてを手前に移動", "Bring All to Front"),
            action: #selector(NSApplication.arrangeInFront(_:)),
            key: "",
            modifiers: [],
            target: NSApp
        ))
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        let helpItem = NSMenuItem()
        let helpMenu = NSMenu(title: L10n.text("ヘルプ", "Help"))
        helpMenu.addItem(menuItem(
            L10n.text("StagePaneの使い方", "StagePane Help"),
            action: #selector(AppController.openHelp),
            key: "?",
            modifiers: [.command],
            target: controller
        ))
        helpItem.submenu = helpMenu
        main.addItem(helpItem)
        NSApp.helpMenu = helpMenu

        return main
    }

    private func snapshotDirectoryArgument() -> URL? {
        let arguments = CommandLine.arguments
        guard let flagIndex = arguments.firstIndex(of: "--snapshot"),
              arguments.indices.contains(flagIndex + 1) else { return nil }
        return URL(fileURLWithPath: arguments[flagIndex + 1], isDirectory: true)
    }

    private func menuItem(
        _ title: String,
        action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags,
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.target = target
        return item
    }
}
