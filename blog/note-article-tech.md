# 「欲しい翻訳ツールがない」から、自分で作ってみた（制作〜リリース全記録）

> 個人開発を副業にしたい人へ。小さなMacアプリを**企画 → 実装 → 配布**するまでに、何を選び、どう作り、いくらかかったのか。技術と工程を全部書きます。

---

## この記事の対象

- 「副業で個人開発をやってみたい」けど、**完成〜リリースまでの全体像**が見えなくて踏み出せていない人
- 「アプリは作れても、**配って人に使ってもらう**ところが分からない」人
- AIコーディング時代に、**非フルタイムエンジニアがどこまでやれるか**を知りたい人

作ったのは **Macのメニューバーに常駐する日↔韓翻訳アプリ**。コードはSwift、頭脳はClaude API。開発は **AI（Claude Code）とのペアプロ**で進めました。

---

## 1. 要件定義：何が「欲しい」のかを言語化する

個人開発で一番大事なのは、**自分が毎日使いたい具体的な不満**を起点にすること。今回はこうでした。

- **常駐**：いつでもサッと呼べる（ブラウザの翻訳サイトを毎回開きたくない）
- **小さく、邪魔にならない**：作業の邪魔をしないUI
- **正確**：ただの機械翻訳ではなく、**固有名詞・専門用語・流行語をネットで確認**して訳す

最後の「正確」が差別化ポイント。ここを技術でどう実現するかが企画の肝になりました。

---

## 2. 技術選定と、その理由

### フロント：なぜ Electron ではなく Swift ネイティブか

| 観点 | Electron | **SwiftUI ネイティブ（採用）** |
|---|---|---|
| 常駐・メニューバー | 可能だが重い | **軽量・OS標準の作法** |
| メモリ/起動 | 重め | **軽い** |
| 配布サイズ | 数百MB | **数MB** |
| 学習コスト | 低 | 中（だがAIが補完） |

「常駐して邪魔にならない」を最優先したので、**SwiftUIのメニューバーアプリ**一択でした。Dockにアイコンを出さない**アクセサリアプリ**にして存在感を消します。

### 頭脳：なぜ Papago/DeepL ではなく Claude API + Web検索か

専用翻訳API（Papago, DeepL）は速くて自然ですが、**ネット検索して文脈の“正解”を取りに行く**ことはできません。

> 例：新しい映画タイトル、人名、ネットスラング → 実際に韓国で使われている表記を**検索してから**訳したい

これを満たせるのが **Claude API の `web_search` ツール**。LLMが必要に応じて自分でWeb検索し、その結果を踏まえて訳します。「正確さ」という要件に直結するので、ここはAI APIを選びました。

---

## 3. 実装のキモ（コード付き）

### (1) デスクトップを自由に動く半透明ウィンドウ

メニューバーのアイコンから、**デスクトップ上を自由に動かせるフローティングウィンドウ**を出します。ポイントは `NSPanel` を透過させ、位置を記憶させること。

```swift
let panel = NSPanel(
    contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
    styleMask: [.titled, .closable, .utilityWindow, .fullSizeContentView],
    backing: .buffered, defer: false
)
panel.contentViewController = NSHostingController(rootView: ContentView())
panel.isFloatingPanel = true
panel.titlebarAppearsTransparent = true
panel.isOpaque = false
panel.backgroundColor = .clear                 // 背景を透過（ターミナル風の半透明に）
panel.isMovableByWindowBackground = true       // どこを掴んでも動かせる
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.setFrameAutosaveName("KoreanTranslatorPanel")  // ★動かした位置を記憶
```

### (2) 翻訳の心臓部：Claude に「検索しながら訳して」と頼む

肝は、リクエストに **`web_search` ツールを持たせる**こと。これだけでLLMが必要に応じて検索してくれます（ツール実行はサーバー側で完結するので、クライアントでループを書く必要なし）。

```swift
var body: [String: Any] = [
    "model": model,                 // 例: claude-sonnet-4-6
    "max_tokens": 2048,
    "system": systemPrompt,         // 「プロの日韓翻訳者として…固有名詞は検索して確認」
    "messages": [["role": "user", "content": text]]
]

// ★ここが差別化の核：Web検索ツールを付与
body["tools"] = [[
    "type": "web_search_20250305",
    "name": "web_search",
    "max_uses": webSearchUses        // 検索回数の上限（コスト管理）
]]

var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
req.httpMethod = "POST"
req.setValue("application/json", forHTTPHeaderField: "content-type")
req.setValue(apiKey,            forHTTPHeaderField: "x-api-key")
req.setValue("2023-06-01",      forHTTPHeaderField: "anthropic-version")
req.httpBody = try JSONSerialization.data(withJSONObject: body)
```

システムプロンプトで出力フォーマットを固定し、訳文と「補足メモ（固有名詞の根拠）」を分離して受け取るようにしています。

### (3) APIキーは Keychain に（ここが後で効いてくる）

ユーザーのAPIキーは `UserDefaults` ではなく **Keychain** に保存。セキュリティ上の当然の選択ですが、**配布設計（後述）に直結する重要な判断**でした。

```swift
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.korean.translator",
    kSecAttrAccount as String: "anthropic-api-key",
    kSecValueData as String: value.data(using: .utf8)!
]
SecItemAdd(query as CFDictionary, nil)
```

---

## 4. デザイン：道具は「毎日触りたくなる見た目」に

最初は **ターミナル風**（半透明グレー＋蛍光グリーンの等幅フォント）。さらに、

- 背景の透け具合・文字色を**スライダーで調整**
- **配色プリセット**（ターミナル緑／ローズゴールド×ベージュ／サクラ など）

色は `Color(hue:saturation:brightness:)` で持たせ、設定値を保存して即反映。地味ですが、**継続して使ってもらう＝プロダクトの生存**に効く部分です。

---

## 5. リリースの壁：「作る」より「配る」が本番

個人開発の挫折ポイントはたいてい**ここ**。順に潰しました。

### (1) `.app` → `.dmg`
ビルドした `.app` に**アイコン（iconutil）を埋め込み**、`codesign` して、ドラッグでインストールできる **`.dmg`** にまとめるスクリプトを用意。ワンコマンドで配布物が出ます。

### (2) Gatekeeper（署名・公証）
ここがMac配布特有の関門。

- **自分・知人向け**：アドホック署名でOK（初回だけ「右クリック→開く」）
- **不特定多数向け**：**Apple Developer Program（年99 USD）**で署名し、`notarytool` で**公証**すれば警告なしで開ける

```bash
xcrun notarytool submit KoreanTranslator.zip \
  --apple-id "..." --team-id "TEAMID" --password "App用パスワード" --wait
xcrun stapler staple KoreanTranslator.app
```

### (3) ホスティングは GitHub で完全無料
- **GitHub Releases** に `.dmg` を置けば固定DLリンクが手に入る
- **GitHub Pages** にダウンロードページを置く（サーバー代ゼロ）

### (4) ★副業的に最重要：「APIキー問題」をどう設計するか

このアプリは動作に**Claude APIキー**が要ります。配布で必ずぶつかる分岐です。

| 方式 | ユーザー体験 | 課金 | 副業的な意味 |
|---|---|---|---|
| **A. BYOK（各自が自分のキー）** | キー取得が必要 | 各自負担 | **無料で配れる/赤字リスクなし**。今回採用 |
| B. 作者のキーを埋め込む | 楽 | 全部作者 | **NG**（抜かれる・乱用・BAN） |
| C. 中継サーバー＋サブスク | 楽 | 作者管理 | **収益化向き**（が、サーバーと課金の実装が必要） |

今回は赤字を出さないため **A（BYOK）** を採用。代わりに、**インストール〜キー取得〜FAQまでの説明書をdmgに同梱**して、非エンジニアでも詰まらないようにしました。

> ここは収益化の本丸でもあります。**無料で配るならA、プロダクトとして課金するならC**。Cにすると「キー不要でそのまま使える」体験を売れるので、サブスクと相性が良い。最初はAで出して反応を見て、伸びそうならCに作り替える、という段階戦略が現実的です。

---

## 6. コストと工数の現実（副業の損益分岐）

| 項目 | 費用 |
|---|---|
| 開発ツール | **0円**（Xcode無料、AIペアプロ） |
| ホスティング（Releases/Pages） | **0円** |
| 配布で警告を消す（任意） | Apple Developer **約99 USD/年** |
| 実行時のAI利用料 | **従量**（BYOKなのでユーザー負担。1翻訳あたり数円以下） |

つまり **「自分と知人に配るだけなら実質0円」**、**「ちゃんと一般配布するなら年1万数千円」** から始められます。

**工数**は、AIとペアプロしたことで体感が激変しました。Swift/AppKitの細かい作法（NSPanelの透過、Keychain、署名フロー）を毎回ググる必要がなく、**「やりたいこと」を言えば叩き台が出る**。非フルタイムでも、要件→実装→配布まで現実的な時間で到達できました。

---

## 7. 副業として見たときの学びと、次の一手

- **企画＝自分の不満の解像度**。汎用ツールより「自分が毎日使う1機能」のほうが完成する
- **差別化は技術の組み合わせ**で作れる（翻訳×Web検索）。ゼロから新技術を発明する必要はない
- **配布・説明・デザインが最後の山**。ここを越えられる人が「作れる人」になる
- **収益化はキー設計とセット**。BYOKで無料配布 → 手応えがあればC（中継＋サブスク）へ

次は、グローバルホットキーで瞬時に呼び出す機能と、**Cモデル（キー不要のサブスク版）**の検証をやってみようと思っています。

---

「欲しいツールがない」は、副業の最高の出発点です。
同じように一歩を踏み出す人の役に立てば嬉しいです🙂
