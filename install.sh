#!/bin/bash
set -e

REPO="Aarontaken/sit-watcher"
APP_NAME="SitWatcher"

# --- step 1: version ---
VERSION="${1:-latest}"
if [ "$VERSION" = "latest" ]; then
    echo "==> Fetching latest version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [ -n "$VERSION" ] || { echo "Error: could not determine latest version"; exit 1; }
fi
echo "   version: $VERSION"

# --- step 2: download ---
ZIP_URL="https://aarontaken.github.io/sit-watcher/$APP_NAME-${VERSION_NUM}.zip"
TMP_DIR=$(mktemp -d)
ZIP_PATH="$TMP_DIR/$APP_NAME.zip"

echo "==> Downloading..."
curl -fsSL --progress-bar -o "$ZIP_PATH" "$ZIP_URL"

# --- step 3: unzip ---
echo "==> Extracting..."
unzip -oq "$ZIP_PATH" -d "$TMP_DIR"

# --- step 4: install ---
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "==> Removing old version..."
    sudo rm -rf "/Applications/$APP_NAME.app"
fi

echo "==> Installing to /Applications..."
sudo cp -R "$TMP_DIR/$APP_NAME.app" "/Applications/"
sudo chown -R "$(whoami):staff" "/Applications/$APP_NAME.app"

# --- step 5: launch ---
echo "==> Launching..."
open "/Applications/$APP_NAME.app"

# --- cleanup ---
rm -rf "$TMP_DIR"

echo ""
echo "  ✓ SitWatcher $VERSION installed and running"
echo ""
