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

/// 背後をぼかす半透明ビュー（ターミナルの半透明背景の質感を出す）。
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.appearance = NSAppearance(named: .darkAqua)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
