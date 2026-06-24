import Foundation
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
    }

    /// 実際にAPIへ渡すWeb検索の最大回数（無効時は0）。
    var effectiveWebSearchUses: Int {
        webSearchEnabled ? max(1, webSearchUses) : 0
    }

    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
