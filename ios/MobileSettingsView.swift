import SwiftUI

struct MobileSettingsView: View {
    @EnvironmentObject var settings: MobileSettings
    @Environment(\.dismiss) private var dismiss
    @State private var keyDraft = ""
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Anthropic APIキー") {
                    HStack {
                        Group {
                            if showKey { TextField("sk-ant-...", text: $keyDraft) }
                            else { SecureField("sk-ant-...", text: $keyDraft) }
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                    }
                    Button("保存") { settings.apiKey = keyDraft }
                        .disabled(keyDraft.isEmpty)
                    if settings.hasAPIKey {
                        Label("保存済み", systemImage: "checkmark.seal.fill").foregroundStyle(Brand.green)
                    }
                    Link("キーを取得する →", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                        .font(.footnote)
                }

                Section("翻訳モデル") {
                    Picker("モデル", selection: $settings.model) {
                        ForEach(MobileSettings.availableModels, id: \.id) { m in
                            Text(m.name).tag(m.id)
                        }
                    }
                }

                Section("ネット検索") {
                    Toggle("固有名詞・専門用語を検索して確認", isOn: $settings.webSearchEnabled)
                    if settings.webSearchEnabled {
                        Stepper("最大検索回数：\(settings.webSearchUses)", value: $settings.webSearchUses, in: 1...10)
                    }
                }

                Section {
                    Text("APIキーは端末内のKeychainに安全に保存され、Anthropic以外には送信されません。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .tint(Brand.green)
            .onAppear { keyDraft = settings.apiKey }
        }
    }
}
