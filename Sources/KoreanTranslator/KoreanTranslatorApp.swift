import SwiftUI
import AppKit

@main
struct KoreanTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(settings)
        } label: {
            // メニューバーに表示する小さなラベル（常駐アイコン）
            Text("韓")
                .font(.system(size: 13, weight: .semibold))
        }
        .menuBarExtraStyle(.window)
    }
}

/// Dock にアイコンを出さず、メニューバー常駐のアクセサリアプリとして動作させる。
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
