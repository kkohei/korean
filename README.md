# 日韓翻訳 (Korean Translator)

**日本語 ⇄ 韓国語** の双方向翻訳アプリです。Claude API の **Web検索ツール**を併用し、
固有名詞・専門用語・流行語などをネットで確認しながら、文脈に合った正確な訳を出力します。

プラットフォームごとに別フォルダで管理しています。

| プラットフォーム | フォルダ | 特徴 | セットアップ |
|---|---|---|---|
| 🖥️ **macOS（デスクトップ）** | [`macos/`](macos/) | メニューバー常駐・フローティングウィンドウ・配色プリセット | [`macos/README.md`](macos/README.md) |
| 📱 **iOS（iPhone）** | [`ios/`](ios/) | 音声入力（マイクで話して翻訳）・TestFlight配布想定 | [`ios/README-iOS.md`](ios/README-iOS.md) |

> 💡 両アプリは翻訳の中核（`TranslationService.swift`）と APIキー保存（`Keychain.swift`）を
> **共有**しています。これらは `macos/Sources/KoreanTranslator/` にあり、iOS版もこの2ファイルを取り込みます。

---

## 翻訳エンジンについて

どちらのアプリも **BYOK（各自が自分の Anthropic APIキーを入力）** 方式です。
キーはアプリ内設定で入力し、端末内に安全に保存されます（macOSはKeychain）。
APIキーの取得手順は各 README に記載しています。

## リポジトリ構成

| フォルダ | 内容 |
|---|---|
| [`macos/`](macos/) | macOSデスクトップアプリ（Swift Package・ビルド/配布スクリプト一式） |
| [`ios/`](ios/) | iOSアプリのソースとセットアップ手順 |
| [`docs/`](docs/) | GitHub Pages 用のダウンロードページ |
| [`guide/`](guide/) | 配布先の人向けの説明書（DMGに同梱） |
| [`blog/`](blog/) | 開発の解説記事 |
