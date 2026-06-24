#!/usr/bin/env bash
#
# KoreanTranslator を .app バンドルとしてビルドするスクリプト。
#
# 使い方:
#   ./build.sh                      … アドホック署名（自分のMacで動かす用）
#   CODESIGN_ID="Developer ID Application: 名前 (TEAMID)" ./build.sh
#                                     … Developer ID で正式署名（配布用）
#
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="release"
APP_NAME="KoreanTranslator"
APP="${APP_NAME}.app"

echo "▶︎ Swift をビルド中 (${CONFIG})…"
swift build -c "${CONFIG}"
BIN_PATH="$(swift build -c "${CONFIG}" --show-bin-path)"

echo "▶︎ アプリバンドルを作成中…"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS"
mkdir -p "${APP}/Contents/Resources"

cp "${BIN_PATH}/${APP_NAME}" "${APP}/Contents/MacOS/${APP_NAME}"
cp "Info.plist" "${APP}/Contents/Info.plist"
printf 'APPL????' > "${APP}/Contents/PkgInfo"

# --- アイコン（AppIcon.iconset -> AppIcon.icns）---
if [ -d "AppIcon.iconset" ] && command -v iconutil >/dev/null 2>&1; then
    echo "▶︎ アイコンを生成中…"
    iconutil -c icns "AppIcon.iconset" -o "${APP}/Contents/Resources/AppIcon.icns"
else
    echo "⚠︎ AppIcon.iconset または iconutil が無いため、アイコンはスキップしました。"
fi

# --- 署名 ---
SIGN_ID="${CODESIGN_ID:-}"
if [ -n "${SIGN_ID}" ]; then
    echo "▶︎ Developer ID で署名中: ${SIGN_ID}"
    codesign --force --deep --options runtime --timestamp \
        --sign "${SIGN_ID}" "${APP}"
    echo "   署名を検証中…"
    codesign --verify --deep --strict --verbose=2 "${APP}"
    echo "   ※配布する場合はこの後ノタライズ（公証）してください（README参照）。"
else
    echo "▶︎ アドホック署名（このMacでの実行用）…"
    codesign --force --deep --sign - "${APP}" >/dev/null 2>&1 || true
fi

echo ""
echo "✅ 完成: ${APP}"
echo ""
echo "起動:        open ${APP}"
echo "インストール: cp -R ${APP} /Applications/  してから Launchpad / Spotlight で起動"
echo ""
echo "起動するとメニューバーに「韓」アイコンが出ます。クリックして使ってください。"
