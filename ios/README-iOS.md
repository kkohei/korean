# iPhone版（音声入力つき）セットアップ手順

Mac版と**翻訳エンジンを共有**したiPhoneアプリです。マイクで話すと、日本語/韓国語を認識して翻訳します（音声入力）。配布は **TestFlight** を想定しています。

> iOSアプリは Swift Package では作れないため、**Xcodeでプロジェクトを作成**して、下記のソースを追加する方式です。

---

## 1. 必要なもの

- **Mac + Xcode 15 以降**
- **iPhone 実機**（音声認識はシミュレータでは動きません。実機推奨）
- **Apple ID**（TestFlight配布には **Apple Developer Program / 年99 USD** が必要）
- **Anthropic APIキー**（アプリ内設定で入力）

---

## 2. Xcodeでプロジェクトを作る

1. Xcode →「File → New → Project」→ **iOS → App**
2. 設定：
   - Product Name：`KoreanTranslatorMobile`
   - Interface：**SwiftUI**／Language：**Swift**
3. 保存先はこのリポジトリの中（例：`ios/` の隣）でOK

## 3. ソースファイルを追加する

作ったプロジェクトに、以下を**ドラッグして追加**します（追加時に「Copy items if needed」と、ターゲットにチェック）。

**iOS専用（`ios/` フォルダ）**
- `KoreanTranslatorMobileApp.swift`
- `MobileContentView.swift`
- `MobileSettingsView.swift`
- `MobileSettings.swift`
- `SpeechRecognizer.swift`

**Mac版と共有（`macos/Sources/KoreanTranslator/` フォルダ）**
- `TranslationService.swift` ← 翻訳の中核（Web検索つきClaude API）
- `Keychain.swift` ← APIキーの安全保存

> Xcodeが自動生成した `ContentView.swift` と `〜App.swift` は重複するので**削除**してください（`@main` が二重定義になるとビルドエラーになります）。

## 4. マイク・音声認識の許可文言を追加

「ターゲット → Info」タブで、次の2つのキーを追加します（値は自由な説明文）。

| キー | 値（例） |
|---|---|
| `Privacy - Microphone Usage Description` (`NSMicrophoneUsageDescription`) | 音声入力で翻訳するためにマイクを使用します。 |
| `Privacy - Speech Recognition Usage Description` (`NSSpeechRecognitionUsageDescription`) | 話した内容を文字に変換するために使用します。 |

これが無いと、マイクを使った瞬間にアプリが落ちます。

## 5. 署名して実機で動かす

1. 「ターゲット → Signing & Capabilities」で **Team** に自分のApple IDを選択
   （特別なCapabilityは不要。Speechは追加設定なしで使えます）
2. iPhoneをケーブル接続 → 実行先に選んで **▶ 実行**
3. 初回は iPhone側で「設定 → 一般 → VPNとデバイス管理」から開発元を信頼

起動したら、⚙設定で **Anthropic APIキー** を入力 → マイクボタンで話す → 翻訳。

---

## 6. TestFlightで身内に配る

1. 「ターゲット → General」で Bundle Identifier をユニークに（例：`com.yourname.koreantranslator`）
2. メニュー「Product → Archive」でアーカイブ作成
3. Organizer →「Distribute App」→ **App Store Connect** へアップロード
4. [App Store Connect](https://appstoreconnect.apple.com) → TestFlight タブ
   - **内部テスター**：自分のチームのApple ID（最大100人、審査なし即時）
   - **外部テスター**：メール招待 or **公開リンク**（最大1万人。簡単なベータ審査あり）
5. 招待された人は **TestFlightアプリ**をインストールして使えます

> TestFlightビルドは約90日で期限切れ。継続するなら新しいビルドを上げ直します。

---

## 7. 構成

| ファイル | 役割 |
|---|---|
| `KoreanTranslatorMobileApp.swift` | アプリのエントリポイント |
| `MobileContentView.swift` | メイン画面（方向切替・入力・マイク・翻訳・結果） |
| `MobileSettingsView.swift` | 設定画面 |
| `MobileSettings.swift` | 設定の保持・永続化 |
| `SpeechRecognizer.swift` | 音声入力（Speechフレームワーク） |
| `TranslationService.swift`（共有） | Web検索つきClaude API呼び出し |
| `Keychain.swift`（共有） | APIキーの安全保存 |

---

## メモ：モバイルでのAPIキーについて

現状は **BYOK（各自が自分のキーを入力）** です。スマホで `sk-ant-...` を手入力するのは少し手間なので、
- iPhoneのパスワード管理（自動入力）に保存しておく
- もしくは将来、**中継サーバー＋サブスク方式**にすればキー入力なしで使えるようになります（別途サーバーが必要）。
