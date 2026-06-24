import SwiftUI

struct MobileContentView: View {
    @EnvironmentObject var settings: MobileSettings
    @EnvironmentObject var history: HistoryStore
    @StateObject private var speech = SpeechRecognizer()
    @StateObject private var speaker = SpeechSynthesizer()

    @State private var input = ""
    @State private var result: TranslationResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var copied = false
    @State private var pulse = false

    private let service = TranslationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    directionBar
                    inputCard
                    micButton
                    translateButton
                    outputCard
                }
                .padding(16)
            }
            .navigationTitle("日韓ほんやく")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHistory = true } label: { Image(systemName: "clock.arrow.circlepath") }
                        .accessibilityLabel("翻訳履歴")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) {
                MobileSettingsView().environmentObject(settings)
            }
            .sheet(isPresented: $showHistory) {
                MobileHistoryView { item in applyHistory(item) }
                    .environmentObject(history)
            }
            .tint(Brand.green)
            // 音声認識の途中経過を入力欄へ反映
            .onChange(of: speech.transcript) { _, newValue in
                if speech.isRecording { input = newValue }
            }
            .onChange(of: speech.errorMessage) { _, newValue in
                if let newValue { errorMessage = newValue }
            }
        }
    }

    // MARK: - 翻訳方向

    private var directionBar: some View {
        HStack(spacing: 12) {
            Text(settings.direction.sourceLabel).font(.headline)
            Button {
                settings.direction = settings.direction.toggled
                result = nil; errorMessage = nil
                if speech.isRecording { speech.stop() }
                speaker.stop()
            } label: {
                Image(systemName: "arrow.left.arrow.right.circle.fill").font(.title2)
            }
            Text(settings.direction.targetLabel).font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - 入力

    private var inputCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground))
            if input.isEmpty {
                Text(speech.isRecording ? "聞き取り中…話してください" : "テキスト入力、またはマイクで話す")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16).padding(.vertical, 16)
            }
            TextEditor(text: $input)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 120)
        }
        .frame(minHeight: 120)
    }

    // MARK: - マイク

    private var micButton: some View {
        Button {
            errorMessage = nil
            speaker.stop()
            speech.toggle(direction: settings.direction)
        } label: {
            ZStack {
                Circle()
                    .fill(speech.isRecording ? Color.red : Brand.green)
                    .frame(width: 76, height: 76)
                    .shadow(color: (speech.isRecording ? Color.red : Brand.green).opacity(0.4), radius: 10)
                    .scaleEffect(pulse && speech.isRecording ? 1.12 : 1.0)
                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: speech.isRecording) { _, rec in
            withAnimation(rec ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true) : .default) {
                pulse = rec
            }
        }
        .accessibilityLabel(speech.isRecording ? "録音を停止" : "音声入力を開始")
    }

    // MARK: - 翻訳

    private var translateButton: some View {
        Button {
            translate()
        } label: {
            HStack {
                if isLoading { ProgressView().tint(.white) }
                Text(isLoading ? "翻訳中…" : "翻訳").bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .background(Brand.green)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(isLoading || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }

    // MARK: - 出力

    @ViewBuilder
    private var outputCard: some View {
        if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red).font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let result {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 14) {
                    Text(result.korean)
                        .font(.title3).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        speaker.toggle(result.korean, direction: settings.direction, rate: Float(settings.speechRate))
                    } label: {
                        Image(systemName: speaker.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                    }
                    .accessibilityLabel(speaker.isSpeaking ? "読み上げを停止" : "結果を読み上げる")
                    Button {
                        UIPasteboard.general.string = result.korean
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .accessibilityLabel("結果をコピー")
                }
                if let notes = result.notes {
                    DisclosureGroup("補足メモ") {
                        Text(notes).font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions

    private func translate() {
        if speech.isRecording { speech.stop() }
        speaker.stop()
        let text = input
        let direction = settings.direction
        errorMessage = nil; result = nil; copied = false; isLoading = true
        Task {
            do {
                let r = try await service.translate(
                    text: text,
                    direction: direction,
                    apiKey: settings.apiKey,
                    model: settings.model,
                    webSearchUses: settings.effectiveWebSearchUses
                )
                await MainActor.run {
                    result = r
                    isLoading = false
                    history.add(source: text, result: r, direction: direction)
                    if settings.autoSpeak {
                        speaker.speak(r.korean, direction: direction, rate: Float(settings.speechRate))
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    /// 履歴から1件を選んだとき、その内容を本画面に復元する。
    private func applyHistory(_ item: HistoryItem) {
        if speech.isRecording { speech.stop() }
        speaker.stop()
        settings.direction = item.direction
        input = item.sourceText
        result = TranslationResult(korean: item.translatedText, notes: item.notes)
        errorMessage = nil
        copied = false
    }
}
