import SwiftUI
import AppKit

@main
struct KoreanTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 実ウィンドウは AppDelegate がフローティングパネルとして管理する。
        // SwiftUI App には最低1つの Scene が必要なため、空の Settings を置く。
        Settings { EmptyView() }
    }
}
