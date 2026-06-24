import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var showKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("設定")
                    .font(.title3.bold())
                Spacer()
                Button("閉じる") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }

            // APIキー
            VStack(alignment: .leading, spacing: 6) {
                Text("Anthropic APIキー")
                    .font(.system(size: 12, weight: .semibold))
                HStack {
                    Group {
                        if showKey {
                            TextField("sk-ant-...", text: $keyDraft)
                        } else {
                            SecureField("sk-ant-...", text: $keyDraft)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                HStack {
                    Button("保存") {
                        settings.apiKey = keyDraft
                    }
                    .buttonStyle(.borderedProminent)
                    if settings.hasAPIKey {
                        Label("保存済み", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Link("キーを取得 →", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                        .font(.system(size: 11))
                }
                Text("キーは macOS の Keychain に安全に保存され、Anthropic以外には送信されません。")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Divider()

            // モデル
            VStack(alignment: .leading, spacing: 6) {
                Text("翻訳モデル")
                    .font(.system(size: 12, weight: .semibold))
                Picker("", selection: $settings.model) {
                    ForEach(AppSettings.availableModels, id: \.id) { m in
                        Text(m.name).tag(m.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            // Web検索
            VStack(alignment: .leading, spacing: 6) {
                Toggle("ネット検索で固有名詞・専門用語を確認する", isOn: $settings.webSearchEnabled)
                    .font(.system(size: 12))
                if settings.webSearchEnabled {
                    Stepper("1回の翻訳での最大検索回数：\(settings.webSearchUses)",
                            value: $settings.webSearchUses, in: 1...10)
                        .font(.system(size: 12))
                    Text("検索回数が多いほど正確になりやすいですが、時間と費用が増えます。")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle("翻訳後に韓国語を自動でコピーする", isOn: $settings.autoCopy)
                .font(.system(size: 12))

            Toggle("ウィンドウを常に最前面に表示する", isOn: $settings.alwaysOnTop)
                .font(.system(size: 12))

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 360, height: 440)
        .onAppear { keyDraft = settings.apiKey }
    }
}
