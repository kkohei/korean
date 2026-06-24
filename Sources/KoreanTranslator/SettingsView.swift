import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var showKey = false

    var body: some View {
        ZStack {
            VisualEffectBackground(light: settings.isLightBackground).ignoresSafeArea()
            settings.backgroundColor.opacity(settings.backgroundOpacity).ignoresSafeArea()

            ScrollView {
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
                        Text("外観")
                            .font(Theme.mono(12, weight: .bold))
                        Spacer()
                        swatch
                        Button("リセット") { settings.resetAppearance() }
                            .font(Theme.mono(10))
                    }

                    // 配色プリセット
                    Text("配色プリセット")
                        .font(Theme.mono(10))
                        .foregroundStyle(settings.textColorDim)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(ThemePreset.presets) { preset in
                            presetChip(preset)
                        }
                    }

                    Text("文字色")
                        .font(Theme.mono(10))
                        .foregroundStyle(settings.textColorDim)
                        .padding(.top, 2)
                    slider("色相", value: $settings.textHue, range: 0.0...1.0)
                    slider("鮮やかさ", value: $settings.textSaturation, range: 0.0...1.0)
                    slider("明るさ", value: $settings.textBrightness, range: 0.2...1.0)

                    Text("背景")
                        .font(Theme.mono(10))
                        .foregroundStyle(settings.textColorDim)
                        .padding(.top, 2)
                    slider("色相", value: $settings.bgHue, range: 0.0...1.0)
                    slider("鮮やかさ", value: $settings.bgSaturation, range: 0.0...1.0)
                    slider("明るさ", value: $settings.bgBrightness, range: 0.0...1.0)
                    slider("濃さ", value: $settings.backgroundOpacity, range: 0.05...0.97)
                }

                Spacer(minLength: 0)
              }
              .padding(16)
            }
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

    /// 現在の文字色／背景色のプレビュー
    private var swatch: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(settings.backgroundColor)
            .frame(width: 34, height: 16)
            .overlay(Text("あ").font(.system(size: 10, weight: .bold)).foregroundStyle(settings.textColor))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(settings.textColorFaint))
    }

    private func presetChip(_ preset: ThemePreset) -> some View {
        let textC = Color(hue: preset.textHue, saturation: preset.textSaturation, brightness: preset.textBrightness)
        let bgC = Color(hue: preset.bgHue, saturation: preset.bgSaturation, brightness: preset.bgBrightness)
        return Button {
            settings.apply(preset)
        } label: {
            Text(preset.name)
                .font(Theme.mono(10, weight: .bold))
                .foregroundStyle(textC)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(bgC)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(textC.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func slider(_ label: String, value: Binding<Double>,
                        range: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Theme.mono(11))
                .frame(width: 72, alignment: .leading)
            Slider(value: value, in: range)
        }
    }
}
