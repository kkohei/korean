# 日韓翻訳 (Korean Translator)

Mac のメニューバーに常駐する、小さな **日本語 → 韓国語** 翻訳アプリです。
Claude API の **Web検索ツール**を併用し、固有名詞・専門用語・流行語などをネットで確認しながら、文脈に合った正確な韓国語を出力します。

- 🪟 デスクトップ上を自由に動かせる小さなフローティングウィンドウ（Dockにアイコンを出さず邪魔にならない）
- 📌 最前面に固定 / 解除を切替可能。ウィンドウ位置は記憶される
- 🌐 ネット検索を使って固有名詞や専門用語まで正確に翻訳
- 📋 クリップボードから貼り付け / 結果を自動コピー
- 🔒 APIキーは macOS の Keychain に安全に保存

---

## 1. 必要なもの

- **macOS 13 (Ventura) 以降**
- **Xcode** または **Xcode Command Line Tools**
  （未インストールならターミナルで `xcode-select --install`）
- **Anthropic APIキー**（次の手順で取得）

---

## 2. Anthropic APIキーの取得手順

1. ブラウザで **https://console.anthropic.com** を開く
2. Google アカウントなどで **サインアップ / ログイン**
3. 左メニュー **Billing（請求）** で支払い方法を登録し、クレジットを購入
   （最低 $5 から。日韓翻訳はとても短いやり取りなので、1回あたり数円程度です）
4. 左メニュー **API keys** → **Create Key** をクリック
5. 表示された **`sk-ant-...`** で始まるキーをコピー
   （このキーは一度しか表示されないので必ずコピー）
6. アプリの **⚙設定** に貼り付けて「保存」

> 💡 キー発行ページへの直リンク: https://console.anthropic.com/settings/keys

---

## 3. ビルドと起動

ターミナルでこのフォルダに移動して、ビルドスクリプトを実行します。

```bash
cd korean
./build.sh
open KoreanTranslator.app
```

- 起動すると、画面右上のメニューバーに **「韓」** アイコンが出ます。クリックでウィンドウの表示/非表示を切り替えられます。
- ウィンドウはタイトルバー（または背景）をドラッグして、**デスクトップの好きな場所へ移動**できます。位置は次回も記憶されます。
- いつも使うなら `KoreanTranslator.app` を `/Applications` に移動してください。
- ログイン時に自動起動したい場合は、**システム設定 → 一般 → ログイン項目** にこのアプリを追加します。

### Xcode で開きたい場合

`Package.swift` を Xcode で開いて（`open Package.swift`）、ターゲットを選んで実行することもできます。

---

## 4. 使い方

1. メニューバーの **「韓」** をクリック
2. 日本語を入力（または **貼り付け** ボタンでクリップボードから取り込み）
3. **翻訳** ボタン、または **⌘ + Return** で翻訳
4. 結果の韓国語右の **コピーボタン** でコピー
5. 固有名詞などの判断根拠がある場合は **補足メモ** に表示されます

### ⚙設定でできること

- **APIキー** の登録・更新
- **翻訳モデル**の切替（Sonnet＝速い / Opus＝最高精度 / Haiku＝最速・低コスト）
- **ネット検索のON/OFF** と最大検索回数
- 翻訳後の **自動コピー**

---

## 5. 初回起動で「開けません」と出たら

自己署名アプリのため、初回は Gatekeeper に止められることがあります。

- `KoreanTranslator.app` を **右クリック → 開く** → ダイアログで **開く**

または:

```bash
xattr -dr com.apple.quarantine KoreanTranslator.app
```

---

## 6. 構成

| ファイル | 役割 |
|---|---|
| `Sources/KoreanTranslator/KoreanTranslatorApp.swift` | アプリのエントリポイント |
| `Sources/KoreanTranslator/AppDelegate.swift` | メニューバー常駐＋フローティングウィンドウ管理 |
| `Sources/KoreanTranslator/ContentView.swift` | 翻訳画面のUI |
| `Sources/KoreanTranslator/SettingsView.swift` | 設定画面 |
| `Sources/KoreanTranslator/TranslationService.swift` | Claude API + Web検索の呼び出し |
| `Sources/KoreanTranslator/AppSettings.swift` | 設定の保持・永続化 |
| `Sources/KoreanTranslator/Keychain.swift` | APIキーのKeychain保存 |
| `build.sh` | `.app` バンドルの生成 |

---

## 7. 費用について

翻訳1回ごとに Claude API の利用料が発生します（テキストが短いので通常はごくわずか）。
Web検索を有効にすると検索1回ごとにも少額の料金がかかります。詳しくは
https://www.anthropic.com/pricing を参照してください。
