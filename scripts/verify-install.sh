#!/bin/bash
# 校验与 install.sh 相同的「解析版本 → 下载 gh-pages zip → 解压」链路，不写入 /Applications。
set -euo pipefail

REPO="Aarontaken/sit-watcher"
APP_NAME="SitWatcher"

VERSION="${1:-latest}"
if [ "$VERSION" = "latest" ]; then
    echo "==> Fetching latest version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [ -n "$VERSION" ] || { echo "Error: could not determine latest version"; exit 1; }
fi
echo "   version: $VERSION"

VERSION_NUM="${VERSION#v}"
ZIP_URL="https://raw.githubusercontent.com/$REPO/gh-pages/$APP_NAME-${VERSION_NUM}.zip"
echo "   ZIP_URL: $ZIP_URL"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Downloading..."
curl -fsSL -o "$TMP_DIR/$APP_NAME.zip" "$ZIP_URL"

echo "==> Extracting..."
unzip -oq "$TMP_DIR/$APP_NAME.zip" -d "$TMP_DIR"

if [ ! -d "$TMP_DIR/$APP_NAME.app" ]; then
    echo "Error: expected $TMP_DIR/$APP_NAME.app"
    ls -la "$TMP_DIR"
    exit 1
fi

if [ ! -f "$TMP_DIR/$APP_NAME.app/Contents/Info.plist" ]; then
    echo "Error: missing Contents/Info.plist"
    exit 1
fi

echo ""
echo "  ✓ verify-install: OK ($VERSION)"
