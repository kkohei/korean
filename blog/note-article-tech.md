# 「欲しい翻訳ツールがない」から、自分で作ってみた（制作〜リリース全記録）

> 個人開発を副業にしたい人へ。Macに常駐する小さな日↔韓翻訳アプリを、**企画 → 技術選定 → 実装 → デザイン → 配布 → 収益化の設計**まで、実際に手を動かした全工程を一本にまとめました。コードもコストも包み隠さず書きます。

![完成したアプリの実使用画面：デスクトップに溶け込む半透明の翻訳ウィンドウ](ここに実機スクショを挿入：ヒーロー)
*▲ 実際の使用画面。メニューバーから呼び出した小さな半透明ウィンドウが、作業の邪魔をせずデスクトップに常駐する。*

---

## もくじ

1. 要件定義 ── 「欲しい」を3つに絞る
2. 技術選定 ── なぜSwiftネイティブ × Claude APIなのか
3. 実装のキモ（コード付き）
4. デザイン ── 毎日触りたくなる見た目をどう作るか
5. リリースの壁 ── 「作る」より「配る」が本番
6. コストと工数のリアル
7. 副業として見たときの戦略と、次の一手
8. まとめ ── あなたが“小さく出す”ためのチェックリスト

---

## 1. 要件定義 ── 「欲しい」を3つに絞る

個人開発がいちばん死にやすいのは、**「あれもこれも」と機能を盛って完成しないこと**。だから最初にやったのは、機能を足すことではなく**削ること**でした。

出発点は、自分の具体的な不満です。

> 韓国語をやりとりするとき、毎回ブラウザの翻訳サイトを開くのが面倒。しかも機械翻訳は、固有名詞や流行語になると平気で外す。

この不満を、**機能要件**と**非機能要件**に分けて言語化しました。

**機能要件（やること）**
- 日本語を入力したら韓国語にする（逆方向も）
- ただの直訳ではなく、**固有名詞・専門用語をネットで確認して正確に**訳す

**非機能要件（体験の質）**
- **常駐**：いつでも1クリックで呼べる
- **小さい・邪魔にならない**：作業画面を覆わない
- **軽い**：常駐するので、メモリも起動も軽量に

ここで大事なのは、「正確さ」という一点を**差別化の軸**に決めたこと。既製の翻訳アプリはたくさんありますが、「**LLMにWeb検索させて文脈ごと正解を取りにいく**」ものは少ない。勝てる土俵を1つ決めて、そこに全リソースを寄せました。

> 💡 副業ポイント：機能の多さでは大手に勝てません。**「自分が毎日困っている1点」**に絞ると、完成するし、刺さる人には深く刺さります。

---

## 2. 技術選定 ── なぜSwiftネイティブ × Claude APIなのか

### 2-1. フロントエンド：Electron / Tauri / SwiftUI

クロスプラットフォームの誘惑（Electron, Tauri）はありましたが、今回の要件は **「macOSで、軽く常駐する」**。マルチOS対応より、**OSネイティブの作法**が効きます。

| 観点 | Electron | Tauri | **SwiftUI（採用）** |
|---|---|---|---|
| 配布サイズ | 数百MB | 数十MB | **数MB** |
| メモリ | 重い | 中 | **軽い** |
| メニューバー常駐 | 可能（やや無理がある） | 可能 | **OS標準の作法** |
| 半透明/ブラー等のOS質感 | 苦手 | 中 | **得意（NSVisualEffectView）** |
| 学習コスト | 低 | 中 | 中（だがAIが補完） |

「常駐して気配を消す」を最優先したので、**SwiftUI + AppKit**に決めました。Swift未経験でも、後述のとおりAIとのペアプロでカバーできます。

### 2-2. 翻訳エンジン：専用翻訳API vs LLM＋Web検索

ここが企画の核。候補はこうでした。

- **Papago / DeepL / Google翻訳API**：速い・自然。でも**「今ネットでどう言われているか」までは見に行けない**
- **Claude API ＋ `web_search` ツール**：必要に応じてLLMが**自分でWeb検索**して、その結果を踏まえて訳す

決め手は具体例でした。

> 「（新作映画のタイトル）が良かった」を訳すとき、機械翻訳はタイトルを直訳してしまう。でも本当に欲しいのは、**韓国で実際に使われている公式タイトル表記**。これは“検索してから訳す”でしか取れない。

「正確さ」という差別化軸に直結するので、**Claude API + Web検索**を採用しました。速度や単純なコストでは専用APIに劣りますが、**勝ちたい土俵で勝てる**選択です。

### 2-3. モデルの選び方

Claudeにも複数のモデルがあります。アプリ内で切り替えられるようにしつつ、デフォルトを決めました。

- **Sonnet（デフォルト）**：速さと品質のバランス。日常の翻訳はこれで十分
- **Opus**：最高精度。固有名詞が多い・ニュアンスが命の長文向け
- **Haiku**：最速・最安。とにかく軽く回したいとき

> 💡 副業ポイント：**「品質×速度×コスト」は1つに決めず、ユーザーに握らせる**と、幅広い人の“ちょうどいい”に当たります。デフォルトだけは作者が責任を持って選ぶ。

---

## 3. 実装のキモ（コード付き）

ここから具体的に。全部は載せきれないので、**“ここが効いた”勘所**だけ抜き出します。

### 3-1. メニューバーに常駐し、Dockから消える

最初はSwiftUIの `MenuBarExtra` で作りました。が、これは**メニューバーにぶら下がる小窓**で、**デスクトップの好きな場所に動かせない**。要件と合わず、後で**`NSStatusItem` ＋ 自前ウィンドウ**へ作り替えました（この“作り直し”も個人開発のリアルです）。

Dockにアイコンを出さない「アクセサリアプリ」化は一行：

```swift
NSApp.setActivationPolicy(.accessory)   // Dockに出さず、メニューバー常駐に徹する
```

メニューバーの「韓」アイコンは `NSStatusItem` で出し、クリックでウィンドウを開閉します。

```swift
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem.button?.attributedTitle = NSAttributedString(
    string: "韓",
    attributes: [.foregroundColor: settings.textNSColor]  // 文字色は設定と連動
)
statusItem.button?.action = #selector(togglePanel)
```

### 3-2. デスクトップを自由に動く、半透明ウィンドウ

要件の「小さい・邪魔にならない・好きな場所に置ける」を満たす中核。`NSPanel` を**透過**させ、**位置を記憶**させます。

```swift
let panel = NSPanel(
    contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
    styleMask: [.titled, .closable, .utilityWindow, .fullSizeContentView],
    backing: .buffered, defer: false
)
panel.contentViewController = NSHostingController(rootView: ContentView())
panel.isFloatingPanel = true                   // 他アプリの上に浮く
panel.titlebarAppearsTransparent = true        // タイトルバーを溶かす
panel.isOpaque = false
panel.backgroundColor = .clear                 // 背景を透過（ここが半透明の肝）
panel.isMovableByWindowBackground = true       // どこを掴んでも動かせる
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.setFrameAutosaveName("KoreanTranslatorPanel")  // ★動かした位置を自動で記憶
```

`setFrameAutosaveName` を入れるだけで、**次に開いたとき前回の位置に出る**。地味ですが「自分の道具」感を大きく左右します。

### 3-3. 翻訳の心臓部：Claudeに「検索しながら訳して」と頼む

肝は、リクエストに **`web_search` ツールを持たせる**こと。これだけでLLMが必要に応じて検索し、結果を踏まえて訳します。しかも**ツールの実行はAnthropic側で完結する**ので、クライアントで「検索→結果を渡してもう一度呼ぶ」というループを書く必要がありません。1回叩けば、検索込みの最終回答が返ります。

```swift
var body: [String: Any] = [
    "model": model,                 // 例: claude-sonnet-4-6
    "max_tokens": 2048,
    "system": systemPrompt,
    "messages": [["role": "user", "content": text]]
]

// ★差別化の核：Web検索ツールを付与
body["tools"] = [[
    "type": "web_search_20250305",
    "name": "web_search",
    "max_uses": webSearchUses        // 検索回数の上限＝コストの蛇口
]]

var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
req.httpMethod = "POST"
req.setValue("application/json", forHTTPHeaderField: "content-type")
req.setValue(apiKey,            forHTTPHeaderField: "x-api-key")
req.setValue("2023-06-01",      forHTTPHeaderField: "anthropic-version")
req.httpBody = try JSONSerialization.data(withJSONObject: body)
```

**システムプロンプトの設計**も品質を左右します。要点はこの3つ。

1. 役割を固定（「プロの日韓翻訳者として」）
2. **検索を使う条件を明示**（固有名詞・専門用語・流行語が来たら検索してから訳す）
3. **出力フォーマットを固定**（訳文と「補足メモ」を区切り文字で分離）

返ってきた本文は、`text` ブロックだけを拾って、自前の区切り（`===NOTES===`）で訳文とメモに割っています。

```swift
let combined = content
    .compactMap { ($0["type"] as? String) == "text" ? $0["text"] as? String : nil }
    .joined()
let parts = combined.components(separatedBy: "===NOTES===")
let korean = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
let notes  = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : nil
```

![翻訳実行後の画面：固有名詞Claudeを原綴りのまま正しく訳している](ここに実機スクショを挿入：翻訳結果)
*▲ 「このアプリはclaudeで作ったよ」→「이 앱은 Claude로 만들었어요」。固有名詞 "Claude" を韓国語にむりやり当て字せず、原綴りのまま残せるのがWeb検索併用の効果。*

### 3-4. APIキーは Keychain に（後の配布設計に直結）

ユーザーのAPIキーは `UserDefaults` ではなく **Keychain** に保存。当然のセキュリティ対応ですが、これが後の「キーをアプリに含めない」配布設計と地続きになります。

```swift
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.korean.translator",
    kSecAttrAccount as String: "anthropic-api-key",
    kSecValueData as String: value.data(using: .utf8)!
]
SecItemDelete(query as CFDictionary)   // 既存を消してから
SecItemAdd(query as CFDictionary, nil) // 入れ直す
```

### 3-5. 双方向対応は「状態」で持つ

日→韓／韓→日は、`enum` の状態として持ち、UIラベル・プレースホルダー・システムプロンプトを切り替えるだけ。最後に使った向きは保存して、次回もそのまま。

```swift
enum TranslationDirection: String {
    case jaToKo, koToJa
    var toggled: TranslationDirection { self == .jaToKo ? .koToJa : .jaToKo }
}
```

> 💡 つまずき：SwiftUIのmacOS対応は、iOSの感覚だと地味にハマります（`TextEditor` の背景を透過するのに `.scrollContentBackground(.hidden)` が要る、等）。こういう細かい“作法”は、**AIに聞くと一発**でした。

---

## 4. デザイン ── 毎日触りたくなる見た目をどう作るか

機能が同じでも、**触りたくなる見た目かどうか**で継続率は変わります。継続率は、個人開発プロダクトの“生存率”そのものです。

最初のテーマは**ターミナル風**。黒地に蛍光グリーンの等幅フォント。背景は `NSVisualEffectView` で後ろをぼかし、その上に半透明色を重ねています。

```swift
struct VisualEffectBackground: NSViewRepresentable {
    var light: Bool = false
    func makeNSView(context: Context) -> NSVisualEffectView { NSVisualEffectView() }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.blendingMode = .behindWindow
        v.state = .active
        v.material = light ? .popover : .hudWindow      // 明るいテーマでは素材も切替
        v.appearance = NSAppearance(named: light ? .aqua : .darkAqua)
    }
}
```

![半透明ウィンドウが壁紙に馴染んでいる様子](ここに実機スクショを挿入：デザイン例)
*▲ 背景をぼかし、その上に半透明の色を重ねている。壁紙に溶け込み“常駐していても気にならない”を実現。*

さらに、**色は数値で持たせて即反映**できるようにしました。

- 文字色・背景色を **HSB（色相・彩度・明度）スライダー**で微調整
- **配色プリセット**をワンタップ（ターミナル緑のほか、ローズゴールド×ベージュ／サクラ／ラベンダー／シャンパン／モノクロ）

```swift
var textColor: Color {
    Color(hue: textHue, saturation: textSaturation, brightness: textBrightness)
}
```

“緑のターミナル”は好みが分かれます。**色を選べる**ようにした瞬間に、刺さる相手が一気に広がりました。見た目のカスタマイズは、自己満足ではなく**ユーザー層を広げる施策**です。

> 💡 副業ポイント：**「機能の差別化」だけでなく「気分の差別化」**も効きます。同じ翻訳でも、自分の好きな色で出てくる道具は、つい使いたくなる。

---

## 5. リリースの壁 ── 「作る」より「配る」が本番

個人開発の挫折はだいたい**ここ**で起きます。動くものができても、人に渡せる形にするまでに段差がいくつもある。順に潰しました。

### 5-1. `.app` バンドルを組み立てる

SwiftのビルドだけではMacアプリになりません。`.app` という決まった**フォルダ構造**に、実行ファイル・`Info.plist`・アイコンを詰めます。

- `Info.plist` に `LSUIElement = true` を入れて**Dockに出さない**
- アイコンは `.iconset`（複数サイズのPNG）を `iconutil` で `.icns` に変換して同梱

```bash
swift build -c release
iconutil -c icns AppIcon.iconset -o KoreanTranslator.app/Contents/Resources/AppIcon.icns
```

### 5-2. Gatekeeper ── Mac配布、最大の関門

ここがMac特有の壁。**署名していないアプリは、初回に「開発元を確認できないため開けません」**と弾かれます。レベルは2段階。

- **自分・知人向け**：アドホック署名でOK（受け取った人は初回だけ「右クリック→開く」）
- **不特定多数向け**：**Apple Developer Program（年99 USD）**の証明書で署名し、**公証（Notarization）**を通すと、警告なしで開けるようになる

```bash
# Developer ID で署名（hardened runtime 付き）
codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_ID" KoreanTranslator.app

# 公証に提出 → 通ったらチケットをアプリに貼る
xcrun notarytool submit KoreanTranslator.zip \
  --apple-id "..." --team-id "TEAMID" --password "App用パスワード" --wait
xcrun stapler staple KoreanTranslator.app
```

どうしても弾かれる人向けに、最終手段の隔離属性削除もドキュメント化しておくと親切です。

```bash
xattr -dr com.apple.quarantine /Applications/KoreanTranslator.app
```

### 5-3. `.dmg` にまとめる

`.zip` でも配れますが、**ドラッグでApplicationsに入れる画面**が出る `.dmg` のほうが圧倒的に親切。`hdiutil` で作れます。`Applications` へのシンボリックリンクを同梱して、“ドラッグ＆ドロップでインストール”の見た目にします。

```bash
ln -s /Applications staging/Applications
hdiutil create -volname "日韓翻訳" -srcfolder staging -ov -format UDZO KoreanTranslator.dmg
```

### 5-4. ホスティングは GitHub で完全無料

サーバー代ゼロで配れます。

- **GitHub Releases** に `.dmg` を上げると、`…/releases/latest/download/KoreanTranslator.dmg` という**固定の最新DLリンク**が手に入る
- **GitHub Pages**（リポジトリの `docs/`）に、ダウンロードボタン付きのページを置く

ダウンロードページもアプリと同じターミナル風で作ると、世界観が一貫してブランドになります。

### 5-5. 最重要：「APIキー問題」をどう設計するか＝収益化の分岐点

このアプリは動作に**ユーザーのClaude APIキー**が要ります。AI系アプリを配るなら必ずぶつかる論点で、ここが**収益化モデルそのもの**になります。

| 方式 | ユーザー体験 | 課金 | 評価 |
|---|---|---|---|
| **A. BYOK（各自が自分のキー）** | キー取得が必要 | 各自負担 | **無料で配れる・赤字リスクなし**。今回採用 |
| B. 作者のキーを埋め込む | 楽 | 全部作者 | **NG**（バイナリから抜かれる・乱用・最悪BAN） |
| C. 中継サーバー＋サブスク | 楽（キー不要） | 作者が管理 | **収益化向き**（が、実装と運用が必要） |

今回は**赤字を出さない**ことを最優先し、**A（BYOK）**を採用。代わりに、非エンジニアでも詰まらないよう**インストール〜キー取得〜FAQまでの説明書を `.dmg` に同梱**しました（受け取った人がdmgを開くと、アプリと並んで「はじめにお読みください」が入っている）。

**Cにするとどうなるか**も設計だけ描いておきます。

```
[アプリ] ──(合言葉/ライセンスキー)──▶ [あなたの中継サーバー(Cloudflare Workers等)]
                                          │ ここにAnthropicキーを隠し持つ
                                          ▼
                                     [Anthropic API]
```

Cの利点は、**「キー不要でそのまま使える」体験を売れる**こと。これは月額サブスクと非常に相性が良い。一方で、**サーバー運用・課金・不正利用対策**という“事業の責任”が発生します。

> 💡 副業の現実解：**まずAで無料配布して反応を見る → 手応えがあればCに作り替えてサブスク化**。最初から事業を背負わず、検証を挟むのが安全です。

---

## 6. コストと工数のリアル

### 6-1. お金

| 項目 | 費用 |
|---|---|
| 開発ツール（Xcode／AIペアプロ） | **0円** |
| ホスティング（Releases／Pages） | **0円** |
| 配布で警告を消す（任意） | Apple Developer **約99 USD/年** |
| 実行時のAI利用料 | **従量**（BYOKなのでユーザー負担） |

1回の翻訳は短いテキストなので、利用料は**数円以下**。Web検索を使っても、検索回数の上限（`max_uses`）で蛇口を絞れます。つまり——

- **自分と知人に配るだけなら、実質0円**
- **一般配布で警告を消すなら、年1万数千円から**

「赤字が怖くて踏み出せない」を、構造的に回避できます。

### 6-2. 時間と、AIペアプロの効き目

正直に言うと、私はSwift/AppKitの専門家ではありません。それでも要件→実装→配布まで到達できたのは、**AI（Claude Code）とのペアプロ**が大きい。具体的にどこが速くなったか：

- **OSの細かい作法**：`NSPanel` の透過、Keychain、署名フロー、`scrollContentBackground` ……毎回ググる時間がほぼ消えた
- **作り直しが怖くない**：MenuBarExtra → NSStatusItem の作り替えのような“方針転換”を、低コストで試せる
- **配布の知識**：notarization や hdiutil など、**普段書かない領域**の手順を即座に手元化できた

> 「コードが書けるか」より、**「やりたいことを言語化できるか」**が効く時代になった、というのが実感です。

---

## 7. 副業として見たときの戦略と、次の一手

工程を振り返って、副業・個人開発の観点での学びを4つ。

1. **企画＝自分の不満の解像度**。汎用ツールより「自分が毎日使う1機能」のほうが完成するし、刺さる
2. **差別化は“組み合わせ”で作る**。翻訳 × Web検索のように、既存技術の掛け算で十分に新しい
3. **配布・署名・説明・デザインが最後の山**。ここを越えられる人が「作れる人」になる
4. **収益化はキー設計とセット**。BYOKで無料配布 → 検証 → C（中継＋サブスク）でマネタイズ、という段階戦略

次にやろうとしているのは、

- **グローバルホットキー**：どのアプリからでも一瞬で呼び出す（常駐ツールの体験が跳ね上がる）
- **選択テキストの即翻訳**：他アプリで選んだ文字をホットキーでそのまま翻訳
- **Cモデルの検証**：キー不要のサブスク版を、まず小さく試す

---

## 8. まとめ ── あなたが“小さく出す”ためのチェックリスト

最後に、この記事の工程を**再現可能なチェックリスト**にしておきます。

- [ ] 自分の**具体的な不満**を1つ選ぶ（汎用化しない）
- [ ] 機能を**3つ以内**に絞る（差別化の軸を1つ決める）
- [ ] OSネイティブか、クロスプラットフォームか、**要件から**選ぶ
- [ ] まず**動くMVP**を出す（見た目は後）
- [ ] **配布の壁**（署名・公証・dmg・ホスティング）を早めに一度通しておく
- [ ] **APIキー／課金の設計**を決める（BYOKで無料検証 → 伸びたらサブスク）
- [ ] 受け取る人向けの**説明書**を同梱する
- [ ] まず**無料で出して、反応を見る**

「欲しいツールがない」は、副業の最高の出発点です。
同じように一歩を踏み出す人の役に立てば嬉しいです🙂

---

### 技術スタックまとめ

- **言語/UI**：Swift / SwiftUI + AppKit（`MenuBarExtra`→`NSStatusItem`＋`NSPanel`）
- **翻訳**：Claude API（Messages API）＋ `web_search` ツール
- **保存**：Keychain（APIキー）／UserDefaults（設定）
- **配布**：`.app`＋`iconutil`＋`codesign`／`hdiutil`（dmg）／GitHub Releases＋Pages
- **開発スタイル**：AI（Claude Code）とのペアプログラミング
