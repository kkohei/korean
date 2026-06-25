#!/usr/bin/env bash
#
# ダブルクリックで「最新取得 → ビルド → 起動」まで一気に行うランチャー。
# Finder でこのファイルをダブルクリックするだけで使えます。
#
set -uo pipefail
cd "$(dirname "$0")"

echo "==============================================="
echo "   日韓翻訳（Mac版）かんたん起動"
echo "==============================================="
echo ""

# 1) 最新コードを取得（失敗しても続行する）
echo "▶︎ 最新版を取得中…"
git pull origin claude/loving-euler-ywkdzd || echo "（取得をスキップしました。オフラインかもしれません）"
echo ""

# 2) ビルド
echo "▶︎ ビルド中…（初回は数分かかることがあります）"
if ! ./build.sh; then
    echo ""
    echo "✗ ビルドに失敗しました。上の赤い文字をコピーして相談してください。"
    echo "（このウィンドウは閉じて大丈夫です）"
    exit 1
fi
echo ""

# 3) 起動（古いものが動いていれば終了してから開き直す）
echo "▶︎ 起動します…"
killall KoreanTranslator >/dev/null 2>&1 || true

# 古いビルド（移動前のリポジトリ直下や /Applications）が残っていると
# そちらが開いてしまうことがあるので掃除する。
rm -rf "../KoreanTranslator.app" 2>/dev/null || true
if [ -d "/Applications/KoreanTranslator.app" ]; then
    echo "  （/Applications の古いコピーを最新版で置き換えます）"
    rm -rf "/Applications/KoreanTranslator.app"
    cp -R "./KoreanTranslator.app" "/Applications/KoreanTranslator.app"
fi

# 必ず今ビルドしたものを絶対パスで開く
open "$PWD/KoreanTranslator.app"
echo ""
echo "✅ 起動しました！メニューバーの「韓」をクリックして使ってください。"
echo "（このターミナルのウィンドウは閉じて構いません）"
