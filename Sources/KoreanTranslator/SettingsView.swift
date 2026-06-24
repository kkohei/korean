import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var showKey = false

    var body: some View {
        ZStack {
            VisualEffectBackground().ignoresSafeArea()
            Color(white: 0.07).opacity(settings.backgroundOpacity).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("設定")
                        .font(Theme.mono(16, weight: .bold))
                    Spacer()
                    Button("閉じる") { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])
                }

                // APIキー
                VStack(alignment: .leading, spacing: 6) {
                    Text("Anthropic APIキー")
                        .font(Theme.mono(12, weight: .bold))
                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-ant-...", text: $keyDraft)
                            } else {
                                SecureField("sk-ant-...", text: $keyDraft)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(Theme.mono(12))
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(settings.textColor)
                    }
                    HStack {
                        Button("保存") {
                            settings.apiKey = keyDraft
                        }
                        .buttonStyle(.borderedProminent)
                        if settings.hasAPIKey {
                            Label("保存済み", systemImage: "checkmark.seal.fill")
                                .font(Theme.mono(11))
                                .foregroundStyle(settings.textColor)
                        }
                        Spacer()
                        Link("キーを取得 →", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                            .font(Theme.mono(11))
                    }
                    Text("キーは macOS の Keychain に安全に保存され、Anthropic以外には送信されません。")
                        .font(Theme.mono(10))
                        .foregroundStyle(settings.textColorDim)
                }

                themedDivider

                // モデル
                VStack(alignment: .leading, spacing: 6) {
                    Text("翻訳モデル")
                        .font(Theme.mono(12, weight: .bold))
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
                        .font(Theme.mono(12))
                    if settings.webSearchEnabled {
                        Stepper("1回の翻訳での最大検索回数：\(settings.webSearchUses)",
                                value: $settings.webSearchUses, in: 1...10)
                            .font(Theme.mono(12))
                        Text("検索回数が多いほど正確になりやすいですが、時間と費用が増えます。")
                            .font(Theme.mono(10))
                            .foregroundStyle(settings.textColorDim)
                    }
                }

                themedDivider

                Toggle("翻訳後に韓国語を自動でコピーする", isOn: $settings.autoCopy)
                    .font(Theme.mono(12))

                Toggle("ウィンドウを常に最前面に表示する", isOn: $settings.alwaysOnTop)
                    .font(Theme.mono(12))

                themedDivider

                // 外観の微調整
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("外観の微調整")
                            .font(Theme.mono(12, weight: .bold))
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(settings.textColor)
                            .frame(width: 26, height: 14)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(settings.textColorFaint))
                        Button("リセット") { settings.resetAppearance() }
                            .font(Theme.mono(10))
                    }

                    slider("背景の濃さ", value: $settings.backgroundOpacity, range: 0.05...0.95)
                    slider("文字色（色相）", value: $settings.textHue, range: 0.0...1.0)
                    slider("文字の鮮やかさ", value: $settings.textSaturation, range: 0.0...1.0)
                    slider("文字の明るさ", value: $settings.textBrightness, range: 0.3...1.0)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(width: 360, height: 600)
        .tint(settings.textColor)
        .foregroundStyle(settings.textColor)
        .onAppear { keyDraft = settings.apiKey }
    }

    private var themedDivider: some View {
        Rectangle()
            .fill(settings.textColorFaint)
            .frame(height: 1)
    }

    private func slider(_ label: String, value: Binding<Double>,
                        range: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Theme.mono(11))
                .frame(width: 104, alignment: .leading)
            Slider(value: value, in: range)
        }
    }
}
