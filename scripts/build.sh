#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/SitWatcher.xcarchive"
APP_NAME="SitWatcher"
DMG_NAME="SitWatcher"
VERSION="${VERSION:-1.0.0}"
VERSION_NUM="${VERSION#v}"
BUILD_NUM="${VERSION_NUM##*.}"

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
  MARKETING_VERSION="$VERSION_NUM" \
  CURRENT_PROJECT_VERSION="$BUILD_NUM" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE="Manual" \
  | xcpretty || xcodebuild archive \
    -project "$PROJECT_DIR/SitWatcher.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    MARKETING_VERSION="$VERSION_NUM" \
    CURRENT_PROJECT_VERSION="$BUILD_NUM" \
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

# Copy and prepare Install.command
cp "$PROJECT_DIR/scripts/Install.command" "$DMG_DIR/Install.command"
chmod +x "$DMG_DIR/Install.command"

# Compile AppleScript installer into a proper .app bundle
echo "==> Building Install.app..."
osacompile -o "$BUILD_DIR/Install.app" "$PROJECT_DIR/scripts/Install.applescript"
# Adhoc-sign the installer app so it shows "unidentified developer" (right-click → Open works)
codesign --force --sign - "$BUILD_DIR/Install.app"
cp -R "$BUILD_DIR/Install.app" "$DMG_DIR/Install.app"

DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
rm -f "$DMG_PATH"

# create-dmg 有时会碰到 hdiutil "资源 busy" 卸载失败；稍等并重试仍可得到 DMG。
sync
sleep 2

dmg_created=0
for attempt in 1 2 3 4 5; do
  rm -f "$DMG_PATH"
  echo "==> create-dmg (attempt $attempt/5)..."
  if create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Install.app" 150 200 \
    --icon "SitWatcher.app" 300 200 \
    --app-drop-link 450 200 \
    --hide-extension "Install.app" \
    "$DMG_PATH" \
    "$DMG_DIR"
  then
    dmg_created=1
    break
  fi
  echo "[WARN] create-dmg failed, waiting before retry..."
  sleep 15
done

if [[ "$dmg_created" -eq 1 ]]; then
  echo "==> DMG created at: $DMG_PATH"
else
  echo "[WARN] DMG was not created after retries (Release .app below is fine)."
fi
echo "==> Release app: $APP_PATH"
echo "==> Done!"
