#!/bin/bash
set -e

REPO="Aarontaken/sit-watcher"
APP_NAME="SitWatcher"

# Determine version (latest by default, or specify e.g. curl ... install.sh | bash -s v1.0.4)
VERSION="${1:-latest}"
if [ "$VERSION" = "latest" ]; then
    echo "Fetching latest version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        echo "Error: could not determine latest version"
        exit 1
    fi
fi
VERSION_NUM="${VERSION#v}"
echo "Version: $VERSION"

# Download DMG
DMG_URL="https://github.com/$REPO/releases/download/$VERSION/$APP_NAME.dmg"
TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/$APP_NAME.dmg"

echo "Downloading ${DMG_URL}..."
curl -fsSL --progress-bar -o "$DMG_PATH" "$DMG_URL"

# Mount DMG
echo "Mounting..."
MOUNT_POINT="$TMP_DIR/mount"
mkdir -p "$MOUNT_POINT"
hdiutil attach -nobrowse -mountpoint "$MOUNT_POINT" "$DMG_PATH" > /dev/null

# Remove old version
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "Removing old version..."
    sudo rm -rf "/Applications/$APP_NAME.app"
fi

# Copy to /Applications
echo "Installing to /Applications..."
sudo cp -R "$MOUNT_POINT/$APP_NAME.app" "/Applications/"
sudo chown -R "$(whoami):staff" "/Applications/$APP_NAME.app"

# Unmount
hdiutil detach "$MOUNT_POINT" -quiet
rm -rf "$TMP_DIR"

# Launch
echo "Launching..."
open "/Applications/$APP_NAME.app"

echo ""
echo "  SitWatcher $VERSION installed and running!"
echo "  It lives in your menu bar (no Dock icon)."
echo ""
