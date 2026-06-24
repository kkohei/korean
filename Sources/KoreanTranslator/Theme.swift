import SwiftUI
import AppKit

/// ターミナル風（半透明グレー＋蛍光グリーン）の配色とフォント。
enum Theme {
    /// 蛍光グリーン（#39FF14 相当）
    static let phosphor = Color(red: 0.22, green: 1.0, blue: 0.08)
    static let phosphorDim = Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.55)
    static let phosphorFaint = Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.30)

    /// AppKit 用の同じ蛍光グリーン（メニューバー文字などに使用）
    static let phosphorNSColor = NSColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 1.0)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// 配色プリセット（文字色・背景色・背景の濃さをまとめて切り替える）。
struct ThemePreset: Identifiable {
    var id: String { name }
    let name: String
    let textHue: Double
    let textSaturation: Double
    let textBrightness: Double
    let bgHue: Double
    let bgSaturation: Double
    let bgBrightness: Double
    let bgOpacity: Double

    static let presets: [ThemePreset] = [
        ThemePreset(name: "ターミナル",
                    textHue: 0.307, textSaturation: 0.92, textBrightness: 1.0,
                    bgHue: 0.0, bgSaturation: 0.0, bgBrightness: 0.07, bgOpacity: 0.55),
        ThemePreset(name: "ローズゴールド×ベージュ",
                    textHue: 0.97, textSaturation: 0.45, textBrightness: 0.66,
                    bgHue: 0.078, bgSaturation: 0.16, bgBrightness: 0.92, bgOpacity: 0.88),
        ThemePreset(name: "サクラ",
                    textHue: 0.934, textSaturation: 0.80, textBrightness: 0.72,
                    bgHue: 0.942, bgSaturation: 0.09, bgBrightness: 0.98, bgOpacity: 0.85),
        ThemePreset(name: "ラベンダー",
                    textHue: 0.748, textSaturation: 0.45, textBrightness: 0.58,
                    bgHue: 0.726, bgSaturation: 0.08, bgBrightness: 0.94, bgOpacity: 0.85),
        ThemePreset(name: "シャンパン",
                    textHue: 0.095, textSaturation: 0.55, textBrightness: 0.55,
                    bgHue: 0.11, bgSaturation: 0.12, bgBrightness: 0.95, bgOpacity: 0.88),
        ThemePreset(name: "モノクロ",
                    textHue: 0.0, textSaturation: 0.0, textBrightness: 0.93,
                    bgHue: 0.0, bgSaturation: 0.0, bgBrightness: 0.10, bgOpacity: 0.6),
    ]
}

/// 背後をぼかす半透明ビュー（ターミナルの半透明背景の質感を出す）。
struct VisualEffectBackground: NSViewRepresentable {
    var light: Bool = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = light ? .popover : .hudWindow
        nsView.appearance = NSAppearance(named: light ? .aqua : .darkAqua)
    }
}
