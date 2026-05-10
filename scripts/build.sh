#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/SitWatcher.xcarchive"
APP_NAME="SitWatcher"
DMG_NAME="SitWatcher"
VERSION="${VERSION:-1.0.0}"

echo "==> Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving Release build..."
xcodebuild archive \
  -project "$PROJECT_DIR/SitWatcher.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE="Manual" \
  | xcpretty || xcodebuild archive \
    -project "$PROJECT_DIR/SitWatcher.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE="Manual"

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"

echo "==> Verifying app exists..."
if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_NAME.app not found at expected path: $APP_PATH"
  exit 1
fi

echo "==> Checking code signature..."
codesign -dvvv "$APP_PATH" 2>&1 || true

echo "==> Creating DMG..."
DMG_DIR="$BUILD_DIR/dmg"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"

ln -s /Applications "$DMG_DIR/Applications" 2>/dev/null || true

DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
rm -f "$DMG_PATH"

hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

echo "==> DMG created at: $DMG_PATH"
echo "==> Done!"
