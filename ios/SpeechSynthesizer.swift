import Foundation
import Combine
import AVFoundation

/// 翻訳結果の読み上げ（Text-to-Speech）。
/// AVSpeechSynthesizer による端末内の音声合成なので、追加コストも通信も発生しない。
/// 翻訳方向に応じて、ターゲット言語（日→韓なら韓国語、韓→日なら日本語）の声で読み上げる。
@MainActor
final class SpeechSynthesizer: NSObject, ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// ターゲット言語のロケール。日→韓なら韓国語、韓→日なら日本語を読み上げる。
    private func languageCode(for direction: TranslationDirection) -> String {
        direction == .jaToKo ? "ko-KR" : "ja-JP"
    }

    func speak(_ text: String, direction: TranslationDirection, rate: Float) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 読み上げ中なら一旦止めてから新しい発話を始める。
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        configureAudioSession()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode(for: direction))
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    /// 読み上げ中なら止め、止まっていれば読み上げる（ボタンのトグル用）。
    func toggle(_ text: String, direction: TranslationDirection, rate: Float) {
        if synthesizer.isSpeaking {
            stop()
        } else {
            speak(text, direction: direction, rate: rate)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// マナーモードでも読み上げが聞こえるよう、再生用カテゴリに切り替える。
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .duckOthers)
        try? session.setActive(true, options: [])
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
