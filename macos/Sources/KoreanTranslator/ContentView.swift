import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings

    @State private var input = ""
    @State private var result: TranslationResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var copied = false

    private let service = TranslationService()

    var body: some View {
        ZStack {
            // ターミナル風：背後ぼかし＋半透明グレーの重ね
            VisualEffectBackground(light: settings.isLightBackground).ignoresSafeArea()
            settings.backgroundColor.opacity(settings.backgroundOpacity).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                header
                inputArea
                actionRow
                terminalDivider
                outputArea
                Spacer(minLength: 0)
                footer
            }
            // 透明タイトルバー分の余白を上に確保
            .padding(EdgeInsets(top: 28, leading: 14, bottom: 12, trailing: 14))
        }
        .frame(width: 360, height: 480)
        .tint(settings.textColor)
        .foregroundStyle(settings.textColor)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(settings)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(settings.direction.headerText)
                .font(Theme.mono(13, weight: .bold))
            Button {
                settings.direction = settings.direction.toggled
                result = nil
                errorMessage = nil
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(settings.textColor)
            .help("翻訳方向を入れ替え")
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(settings.textColor)
            .help("設定")
        }
    }

    // MARK: - Input

    private var inputArea: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(settings.textColorFaint, lineWidth: 1)
            TextEditor(text: $input)
                .font(Theme.mono(14))
                .foregroundColor(settings.textColor)
                .scrollContentBackground(.hidden)
                .padding(6)
            if input.isEmpty {
                Text(settings.direction.inputPlaceholder)
                    .foregroundStyle(settings.textColorDim)
                    .font(Theme.mono(14))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 110)
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                pasteFromClipboard()
            } label: {
                Label("貼り付け", systemImage: "doc.on.clipboard")
            }
            .help("クリップボードの文字を入力欄に貼り付け")

            Button {
                input = ""
                result = nil
                errorMessage = nil
            } label: {
                Label("クリア", systemImage: "trash")
            }
            .disabled(input.isEmpty && result == nil)

            Spacer()

            Button {
                translate()
            } label: {
                Label("翻訳", systemImage: "arrow.right.circle.fill")
            }
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("⌘↩ で翻訳")
        }
        .font(Theme.mono(12))
    }

    private var terminalDivider: some View {
        Rectangle()
            .fill(settings.textColorFaint)
            .frame(height: 1)
    }

    // MARK: - Output

    private var outputArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text(settings.effectiveWebSearchUses > 0
                             ? "ネット検索しながら翻訳中…"
                             : "翻訳中…")
                            .foregroundStyle(settings.textColorDim)
                            .font(Theme.mono(13))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.35))
                        .font(Theme.mono(13))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let result {
                    resultView(result)
                } else {
                    Text("結果がここに表示されます。")
                        .foregroundStyle(settings.textColorFaint)
                        .font(Theme.mono(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultView(_ result: TranslationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(result.korean)
                    .font(Theme.mono(16, weight: .medium))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    copyToClipboard(result.korean)
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(settings.textColor)
                .help(settings.direction.copyHelp)
            }

            if let notes = result.notes {
                DisclosureGroup("補足メモ") {
                    Text(notes)
                        .font(Theme.mono(12))
                        .foregroundStyle(settings.textColorDim)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(Theme.mono(12))
                .tint(settings.textColor)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if !settings.hasAPIKey {
                Label("APIキー未設定", systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.mono(11))
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.2))
                    .onTapGesture { showSettings = true }
            } else {
                Text(modelLabel)
                    .font(Theme.mono(11))
                    .foregroundStyle(settings.textColorDim)
            }
            Spacer()
            Button {
                settings.alwaysOnTop.toggle()
            } label: {
                Image(systemName: settings.alwaysOnTop ? "pin.fill" : "pin.slash")
            }
            .buttonStyle(.borderless)
            .font(Theme.mono(11))
            .foregroundStyle(settings.alwaysOnTop ? settings.textColor : settings.textColorDim)
            .help(settings.alwaysOnTop ? "最前面に固定中（クリックで解除）" : "最前面固定は解除中")

            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(Theme.mono(11))
            .foregroundStyle(settings.textColorDim)
        }
    }

    private var modelLabel: String {
        let name = AppSettings.availableModels.first { $0.id == settings.model }?.name ?? settings.model
        return settings.effectiveWebSearchUses > 0 ? "\(name)・Web検索ON" : "\(name)・Web検索OFF"
    }

    // MARK: - Actions

    private func translate() {
        let text = input
        errorMessage = nil
        result = nil
        copied = false
        isLoading = true
        Task {
            do {
                let r = try await service.translate(
                    text: text,
                    direction: settings.direction,
                    apiKey: settings.apiKey,
                    model: settings.model,
                    webSearchUses: settings.effectiveWebSearchUses
                )
                await MainActor.run {
                    self.result = r
                    self.isLoading = false
                    if settings.autoCopy { copyToClipboard(r.korean) }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func pasteFromClipboard() {
        if let s = NSPasteboard.general.string(forType: .string), !s.isEmpty {
            input = s
        }
    }

    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            copied = false
        }
    }
}
