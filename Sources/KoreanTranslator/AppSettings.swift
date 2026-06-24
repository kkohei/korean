import SwiftUI
import AppKit
import Combine

/// アプリ設定。APIキーは Keychain、その他は UserDefaults に永続化する。
final class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet { Keychain.save(apiKey) }
    }
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "model") }
    }
    @Published var webSearchEnabled: Bool {
        didSet { UserDefaults.standard.set(webSearchEnabled, forKey: "webSearchEnabled") }
    }
    @Published var webSearchUses: Int {
        didSet { UserDefaults.standard.set(webSearchUses, forKey: "webSearchUses") }
    }
    @Published var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: "autoCopy") }
    }
    /// ウィンドウを常に最前面に表示するか。
    @Published var alwaysOnTop: Bool {
        didSet { UserDefaults.standard.set(alwaysOnTop, forKey: "alwaysOnTop") }
    }
    /// 翻訳の方向（日→韓 / 韓→日）。
    @Published var direction: TranslationDirection {
        didSet { UserDefaults.standard.set(direction.rawValue, forKey: "direction") }
    }

    // MARK: - 外観（スライダーで微調整）

    /// 背景の不透明度（0=透明〜0.95=ほぼ不透明）
    @Published var backgroundOpacity: Double {
        didSet { UserDefaults.standard.set(backgroundOpacity, forKey: "backgroundOpacity") }
    }
    /// 文字色の色相（0〜1）
    @Published var textHue: Double {
        didSet { UserDefaults.standard.set(textHue, forKey: "textHue") }
    }
    /// 文字色の彩度（0〜1）
    @Published var textSaturation: Double {
        didSet { UserDefaults.standard.set(textSaturation, forKey: "textSaturation") }
    }
    /// 文字色の明度（0〜1）
    @Published var textBrightness: Double {
        didSet { UserDefaults.standard.set(textBrightness, forKey: "textBrightness") }
    }

    // 蛍光グリーン #39FF14 の HSB 既定値
    static let defaultHue = 0.307
    static let defaultSaturation = 0.92
    static let defaultBrightness = 1.0
    static let defaultBackgroundOpacity = 0.55

    /// 選択可能なモデル一覧（表示名, モデルID）
    static let availableModels: [(name: String, id: String)] = [
        ("Sonnet 4.6（推奨・速い）", "claude-sonnet-4-6"),
        ("Opus 4.8（最高精度）", "claude-opus-4-8"),
        ("Haiku 4.5（最速・低コスト）", "claude-haiku-4-5-20251001")
    ]

    init() {
        let d = UserDefaults.standard
        // init 内の代入では didSet は発火しないため、Keychain への再保存は起きない。
        apiKey = Keychain.load()
        model = d.string(forKey: "model") ?? "claude-sonnet-4-6"
        webSearchEnabled = (d.object(forKey: "webSearchEnabled") as? Bool) ?? true
        webSearchUses = (d.object(forKey: "webSearchUses") as? Int) ?? 5
        autoCopy = (d.object(forKey: "autoCopy") as? Bool) ?? false
        alwaysOnTop = (d.object(forKey: "alwaysOnTop") as? Bool) ?? true
        direction = TranslationDirection(rawValue: d.string(forKey: "direction") ?? "") ?? .jaToKo
        backgroundOpacity = (d.object(forKey: "backgroundOpacity") as? Double) ?? Self.defaultBackgroundOpacity
        textHue = (d.object(forKey: "textHue") as? Double) ?? Self.defaultHue
        textSaturation = (d.object(forKey: "textSaturation") as? Double) ?? Self.defaultSaturation
        textBrightness = (d.object(forKey: "textBrightness") as? Double) ?? Self.defaultBrightness
    }

    // MARK: - 外観の派生値

    var textColor: Color { Color(hue: textHue, saturation: textSaturation, brightness: textBrightness) }
    var textColorDim: Color { textColor.opacity(0.55) }
    var textColorFaint: Color { textColor.opacity(0.30) }
    var textNSColor: NSColor {
        NSColor(hue: CGFloat(textHue), saturation: CGFloat(textSaturation),
                brightness: CGFloat(textBrightness), alpha: 1.0)
    }

    func resetAppearance() {
        textHue = Self.defaultHue
        textSaturation = Self.defaultSaturation
        textBrightness = Self.defaultBrightness
        backgroundOpacity = Self.defaultBackgroundOpacity
    }

    /// 実際にAPIへ渡すWeb検索の最大回数（無効時は0）。
    var effectiveWebSearchUses: Int {
        webSearchEnabled ? max(1, webSearchUses) : 0
    }

    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
