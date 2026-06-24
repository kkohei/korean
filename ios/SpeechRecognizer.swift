import Foundation
import Speech
import AVFoundation

/// iOSの音声入力（Speech フレームワーク）。翻訳方向に応じて日本語/韓国語を認識する。
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private func locale(for direction: TranslationDirection) -> Locale {
        direction == .jaToKo ? Locale(identifier: "ja-JP") : Locale(identifier: "ko-KR")
    }

    func toggle(direction: TranslationDirection) {
        if isRecording { stop() } else { start(direction: direction) }
    }

    func start(direction: TranslationDirection) {
        errorMessage = nil
        transcript = ""
        requestAuthorizations { [weak self] granted in
            guard let self else { return }
            if granted {
                self.beginSession(direction: direction)
            } else {
                self.errorMessage = "マイクと音声認識の許可が必要です（設定アプリ ＞ プライバシー）。"
            }
        }
    }

    private func requestAuthorizations(_ completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            let speechOK = (speechStatus == .authorized)
            let micHandler: (Bool) -> Void = { micOK in
                DispatchQueue.main.async { completion(speechOK && micOK) }
            }
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission(completionHandler: micHandler)
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission(micHandler)
            }
        }
    }

    private func beginSession(direction: TranslationDirection) {
        guard let rec = SFSpeechRecognizer(locale: locale(for: direction)), rec.isAvailable else {
            errorMessage = "この言語の音声認識が利用できません。"
            return
        }
        recognizer = rec

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true

            task = rec.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    Task { @MainActor in self.transcript = result.bestTranscription.formattedString }
                }
                if error != nil || (result?.isFinal ?? false) {
                    Task { @MainActor in self.stop() }
                }
            }
        } catch {
            errorMessage = "マイクを開始できませんでした：\(error.localizedDescription)"
            stop()
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
