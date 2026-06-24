# 日韓翻訳 (Korean Translator)

Mac のメニューバーに常駐する、小さな **日本語 ⇄ 韓国語** 翻訳アプリです（双方向対応）。

> 📱 **iPhone版（音声入力つき）** も用意しています → [`ios/README-iOS.md`](ios/README-iOS.md)
> 翻訳エンジンを共有し、マイクで話して翻訳できます（配布はTestFlight想定）。
Claude API の **Web検索ツール**を併用し、固有名詞・専門用語・流行語などをネットで確認しながら、文脈に合った正確な韓国語を出力します。

- 🔁 日本語 → 韓国語 / 韓国語 → 日本語 の双方向（入れ替えボタンで切替・方向を記憶）
- 🖥️ ターミナル風デザイン（半透明グレー背景＋蛍光グリーンの等幅文字）
- 🎛️ 配色プリセット（ターミナル緑／ローズゴールド×ベージュ／サクラ／ラベンダー／シャンパン／モノクロ）＋文字色・背景色をスライダーで微調整
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
2. 上部の **⇄ 入れ替えボタン**で翻訳方向（日→韓 / 韓→日）を選ぶ
3. 文章を入力（または **貼り付け** ボタンでクリップボードから取り込み）
3. **翻訳** ボタン、または **⌘ + Return** で翻訳
4. 結果の韓国語右の **コピーボタン** でコピー
5. 固有名詞などの判断根拠がある場合は **補足メモ** に表示されます

### ⚙設定でできること

- **APIキー** の登録・更新
- **翻訳モデル**の切替（Sonnet＝速い / Opus＝最高精度 / Haiku＝最速・低コスト）
- **ネット検索のON/OFF** と最大検索回数
- 翻訳後の **自動コピー**
- **外観**（配色プリセットをワンタップ選択／文字色・背景色をHSBスライダーで微調整。リセットでターミナル緑に戻る）

---

## 5. 初回起動で「開けません」と出たら

自己署名アプリのため、初回は Gatekeeper に止められることがあります。

- `KoreanTranslator.app` を **右クリック → 開く** → ダイアログで **開く**

または:

```bash
xattr -dr com.apple.quarantine KoreanTranslator.app
```

---

## 6. 配布用のちゃんとした署名・公証（任意）

自分の Mac で使うだけなら `./build.sh`（アドホック署名）で十分です。
**他人に配って警告なしで開けるようにする**には、Apple Developer Program（年 99 USD）の証明書で署名し、公証（Notarization）します。

1. **Developer ID 証明書を用意**
   - [Apple Developer Program](https://developer.apple.com/programs/) に登録
   - Xcode →「Settings → Accounts」でログイン →「Manage Certificates」→ ＋ →「Developer ID Application」を作成
2. **署名してビルド**（証明書名は「キーチェーンアクセス」で確認できます）
   ```bash
   CODESIGN_ID="Developer ID Application: あなたの名前 (TEAMID)" ./build.sh
   ```
3. **公証（Notarization）**（初回は App用パスワードを発行：appleid.apple.com）
   ```bash
   # zip にまとめて提出
   ditto -c -k --keepParent KoreanTranslator.app KoreanTranslator.zip
   xcrun notarytool submit KoreanTranslator.zip \
     --apple-id "あなたのAppleID" \
     --team-id "TEAMID" \
     --password "App用パスワード" --wait
   # 通ったらチケットをアプリに貼り付け
   xcrun stapler staple KoreanTranslator.app
   ```

これで、配布先の Mac でも右クリックなしでそのまま開けるようになります。

---

## 7. 構成

| ファイル | 役割 |
|---|---|
| `Sources/KoreanTranslator/KoreanTranslatorApp.swift` | アプリのエントリポイント |
| `Sources/KoreanTranslator/AppDelegate.swift` | メニューバー常駐＋フローティングウィンドウ管理 |
| `Sources/KoreanTranslator/ContentView.swift` | 翻訳画面のUI |
| `Sources/KoreanTranslator/SettingsView.swift` | 設定画面 |
| `Sources/KoreanTranslator/TranslationService.swift` | Claude API + Web検索の呼び出し |
| `Sources/KoreanTranslator/AppSettings.swift` | 設定の保持・永続化 |
| `Sources/KoreanTranslator/Keychain.swift` | APIキーのKeychain保存 |
| `Sources/KoreanTranslator/Theme.swift` | 配色・等幅フォント・半透明背景 |
| `AppIcon.iconset/` | アプリアイコン（ビルド時に `.icns` へ変換） |
| `build.sh` | `.app` バンドルの生成・アイコン埋め込み・署名 |
| `make-dmg.sh` | 配布用 `.dmg` の作成 |
| `docs/index.html` | GitHub Pages 用ダウンロードページ |
| `INSTALL.md` | 配布先の人向けインストール手順（テキスト版） |
| `guide/manual.html` | 配布先の人向けの説明書（DMGに自動同梱・ブラウザで開く） |

---

## 8. 個人で配布する

### (1) 配布用 DMG を作る

```bash
./make-dmg.sh              # KoreanTranslator.dmg ができる
```

「アプリを Applications へドラッグ」する画面付きの `.dmg` が生成されます。
正式署名する場合は `CODESIGN_ID="Developer ID Application: 名前 (TEAMID)" ./make-dmg.sh`。

### (2) GitHub Releases に置く（ダウンロードURLができる）

1. GitHub のリポジトリ →「Releases」→「Draft a new release」
2. タグ（例 `v1.0`）を付けて、作った `KoreanTranslator.dmg` を **そのままのファイル名で**添付
3. Publish すると、固定URL `…/releases/latest/download/KoreanTranslator.dmg` で配れます

### (3) ダウンロードページ（GitHub Pages）

`docs/index.html` がダウンロードボタン付きの配布ページです。

1. GitHub のリポジトリ →「Settings → Pages」
2. 「Build and deployment」の Source を **Deploy from a branch**、ブランチを `main`、フォルダを **/docs** に設定
3. 数分後に `https://kkohei.github.io/korean/` で公開されます
   （ダウンロードボタンは上記 (2) の Release ファイルを指します）

### (4) 受け取る人への案内（説明書を同梱）

`./make-dmg.sh` で作る `.dmg` には、初心者向けの説明書 **「はじめにお読みください.html」**（`guide/manual.html`）が自動で同梱されます。
受け取った人が dmg を開くと、アプリと一緒にこの説明書が入っているので、**ダブルクリックすればブラウザで開いて**、インストール〜APIキー取得〜使い方まで順番に読めます。

> APIキーは各自が自分のものを取得して使う方式です（あなたのキーは含まれず、課金も各自）。説明書にその旨と取得手順を丁寧に書いてあります。

---

## 9. 費用について

翻訳1回ごとに Claude API の利用料が発生します（テキストが短いので通常はごくわずか）。
Web検索を有効にすると検索1回ごとにも少額の料金がかかります。詳しくは
https://www.anthropic.com/pricing を参照してください。
