#!/usr/bin/env bash
#
# KoreanTranslator.app を配布用の .dmg にまとめるスクリプト。
# build.sh を呼んでからディスクイメージを作ります。
#
# 使い方:
#   ./make-dmg.sh
#   CODESIGN_ID="Developer ID Application: 名前 (TEAMID)" ./make-dmg.sh   # 正式署名
#
set -euo pipefail
cd "$(dirname "$0")"

APP="KoreanTranslator.app"
DMG="KoreanTranslator.dmg"
VOL_NAME="日韓翻訳"

# まずアプリをビルド（CODESIGN_ID はそのまま build.sh に引き継がれる）
./build.sh

if [ ! -d "${APP}" ]; then
    echo "✗ ${APP} が見つかりません。ビルドに失敗しています。" >&2
    exit 1
fi

echo "▶︎ ディスクイメージを作成中…"
rm -f "${DMG}"
STAGING="$(mktemp -d)"
cp -R "${APP}" "${STAGING}/"
# 「Applicationsへドラッグ」用のショートカット
ln -s /Applications "${STAGING}/Applications"
# 使い方の説明書を同梱（ダブルクリックでブラウザが開く）
if [ -f "guide/manual.html" ]; then
    cp "guide/manual.html" "${STAGING}/はじめにお読みください.html"
fi

hdiutil create -volname "${VOL_NAME}" \
    -srcfolder "${STAGING}" \
    -ov -format UDZO "${DMG}"
rm -rf "${STAGING}"

# 配布で公証する場合は .dmg 自体も署名しておく
SIGN_ID="${CODESIGN_ID:-}"
if [ -n "${SIGN_ID}" ]; then
    echo "▶︎ DMG を署名中…"
    codesign --force --sign "${SIGN_ID}" "${DMG}"
fi

echo ""
echo "✅ 完成: ${DMG}"
echo "   この .dmg を配布、または GitHub Releases に KoreanTranslator.dmg として添付してください。"
echo "   （配布前に正式に公証する場合は README セクション6を参照）"
