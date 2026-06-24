import SwiftUI

@main
struct KoreanTranslatorMobileApp: App {
    @StateObject private var settings = MobileSettings()

    var body: some Scene {
        WindowGroup {
            MobileContentView()
                .environmentObject(settings)
        }
    }
}

/// ブランドカラー（蛍光グリーンをモバイル向けに少し落ち着かせた緑）
enum Brand {
    static let green = Color(red: 0.16, green: 0.72, blue: 0.42)
}
