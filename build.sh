#!/usr/bin/env bash
#
# KoreanTranslator を .app バンドルとしてビルドするスクリプト。
# 使い方:  ./build.sh   (ビルド後 ./KoreanTranslator.app が出来ます)
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

# 自己署名（任意・あると初回起動の警告が減ることがある）
if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "${APP}" >/dev/null 2>&1 || true
fi

echo ""
echo "✅ 完成: ${APP}"
echo ""
echo "起動:        open ${APP}"
echo "インストール: cp -R ${APP} /Applications/  してから Launchpad / Spotlight で起動"
echo ""
echo "起動するとメニューバーに「韓」アイコンが出ます。クリックして使ってください。"
