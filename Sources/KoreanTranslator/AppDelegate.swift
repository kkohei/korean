import SwiftUI
import AppKit
import Combine

/// メニューバー常駐アイコンと、デスクトップ上を自由に動かせるフローティングウィンドウを管理する。
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock にアイコンを出さないアクセサリアプリにする。
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPanel()
        applyAlwaysOnTop(settings.alwaysOnTop)

        // 「最前面に固定」設定の変更を監視してウィンドウのレベルを更新する。
        settings.$alwaysOnTop
            .receive(on: RunLoop.main)
            .sink { [weak self] on in self?.applyAlwaysOnTop(on) }
            .store(in: &cancellables)

        // 文字色の変更をメニューバーの「韓」に反映する。
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                DispatchQueue.main.async { self?.updateStatusItemColor() }
            }
            .store(in: &cancellables)

        // 初回起動時はウィンドウを表示して場所を知らせる。
        showPanel()
    }

    // MARK: - メニューバーアイコン

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePanel)
            button.toolTip = "日韓翻訳（クリックで開閉）"
        }
        updateStatusItemColor()
    }

    /// メニューバーの「韓」を現在の文字色で描き直す。
    private func updateStatusItemColor() {
        statusItem?.button?.attributedTitle = NSAttributedString(
            string: "韓",
            attributes: [
                .foregroundColor: settings.textNSColor,
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
            ]
        )
    }

    // MARK: - フローティングウィンドウ

    private func setupPanel() {
        let hosting = NSHostingController(rootView: ContentView().environmentObject(settings))

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.titled, .closable, .utilityWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hosting
        panel.title = "日韓翻訳"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false        // 他アプリを使っても消えない
        panel.isReleasedWhenClosed = false     // 閉じても破棄しない（再表示できる）
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        // ターミナル風の半透明背景：タイトルバーを透明にし、ウィンドウ自体を透過させる。
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.appearance = NSAppearance(named: .darkAqua)

        // 位置はユーザーが動かした場所を記憶する。初回は画面中央。
        panel.setFrameAutosaveName("KoreanTranslatorPanel")
        if panel.frame.origin == .zero {
            panel.center()
        }
        self.panel = panel
    }

    private func applyAlwaysOnTop(_ on: Bool) {
        panel?.level = on ? .floating : .normal
    }

    // MARK: - 表示制御

    @objc private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let panel else { return }
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
