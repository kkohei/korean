import SwiftUI

@main
struct KoreanTranslatorMobileApp: App {
    @StateObject private var settings = MobileSettings()
    @StateObject private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            MobileContentView()
                .environmentObject(settings)
                .environmentObject(history)
        }
    }
}

/// ブランドカラー（蛍光グリーンをモバイル向けに少し落ち着かせた緑）
enum Brand {
    static let green = Color(red: 0.16, green: 0.72, blue: 0.42)
}
