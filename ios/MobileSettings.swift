import SwiftUI
import Combine
import AVFoundation

/// iOS版アプリの設定。APIキーは Keychain、その他は UserDefaults に保存。
/// 翻訳の中核（TranslationService / Keychain / TranslationDirection）はmacOS版と共有。
final class MobileSettings: ObservableObject {
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
    @Published var direction: TranslationDirection {
        didSet { UserDefaults.standard.set(direction.rawValue, forKey: "direction") }
    }
    /// 翻訳後に結果を自動で読み上げるか。
    @Published var autoSpeak: Bool {
        didSet { UserDefaults.standard.set(autoSpeak, forKey: "autoSpeak") }
    }
    /// 読み上げ速度（AVSpeechUtterance の rate。0.0〜1.0、標準は約0.5）。
    @Published var speechRate: Double {
        didSet { UserDefaults.standard.set(speechRate, forKey: "speechRate") }
    }

    static let availableModels: [(name: String, id: String)] = [
        ("Sonnet（推奨・速い）", "claude-sonnet-4-6"),
        ("Opus（最高精度）", "claude-opus-4-8"),
        ("Haiku（最速・低コスト）", "claude-haiku-4-5-20251001")
    ]

    init() {
        let d = UserDefaults.standard
        apiKey = Keychain.load()
        model = d.string(forKey: "model") ?? "claude-sonnet-4-6"
        webSearchEnabled = (d.object(forKey: "webSearchEnabled") as? Bool) ?? true
        webSearchUses = (d.object(forKey: "webSearchUses") as? Int) ?? 5
        direction = TranslationDirection(rawValue: d.string(forKey: "direction") ?? "") ?? .jaToKo
        autoSpeak = (d.object(forKey: "autoSpeak") as? Bool) ?? true
        speechRate = (d.object(forKey: "speechRate") as? Double) ?? Double(AVSpeechUtteranceDefaultSpeechRate)
    }

    var effectiveWebSearchUses: Int { webSearchEnabled ? max(1, webSearchUses) : 0 }
    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
