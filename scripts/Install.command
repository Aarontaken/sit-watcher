#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="SitWatcher"
APP_PATH="$SCRIPT_DIR/$APP_NAME.app"
TARGET="/Applications/$APP_NAME.app"

echo "==========================================="
echo "  SitWatcher 安装器"
echo "==========================================="
echo ""

# Step 1: Remove quarantine from the bundled app
echo "→ 移除隔离标记..."
if [ -d "$APP_PATH" ]; then
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
    echo "  完成。"
else
    echo "  ✗ 错误：找不到 SitWatcher.app"
    echo "  请确保 Install.command 和 SitWatcher.app 在同一个文件夹中。"
    read -p "按回车键退出..."
    exit 1
fi

# Step 2: Remove old version if exists
if [ -d "$TARGET" ]; then
    echo "→ 移除旧版本..."
    rm -rf "$TARGET"
fi

# Step 3: Copy to /Applications
echo "→ 安装到 /Applications..."
cp -R "$APP_PATH" "$TARGET"

# Step 4: Also remove quarantine from the installed copy (just in case)
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

echo "→ 安装完成！"

# Step 5: Launch the app
echo "→ 启动 SitWatcher..."
open "$TARGET"

echo ""
echo "SitWatcher 已安装并启动。你可以关闭此窗口了。"
echo ""
read -p "按回车键退出..."
