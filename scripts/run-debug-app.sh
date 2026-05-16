#!/usr/bin/env bash
# Debug 构建并本地启动 SitWatcher。
# 本应用无 Dock（LSUIElement），启动后请到屏幕右上角菜单栏找小人坐姿图标；
# MacBook 刘海机型若看不到，可先点刘海旁的「⋯」(Control Center/More) 展开的菜单栏区域。
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="$PROJECT_DIR/build/debug-derived"
APP="$DERIVED/Build/Products/Debug/SitWatcher.app"

echo "==> xcodegen"
cd "$PROJECT_DIR"
xcodegen generate -q

echo "==> xcodebuild Debug (derived data: ${DERIVED#"$PROJECT_DIR"/})"
mkdir -p "$(dirname "$DERIVED")"
xcodebuild \
  -scheme SitWatcher \
  -configuration Debug \
  -derivedDataPath "$DERIVED" \
  build \
  ONLY_ACTIVE_ARCH=YES \
  >/dev/null

if [[ ! -d "$APP" ]]; then
  echo "找不到构建产物：$APP" >&2
  exit 1
fi

killall SitWatcher 2>/dev/null || true
sleep 0.5
open -na "$APP"

echo ""
echo "━━━━━━━━ SitWatcher ━━━━━━━━"
echo "已从 Debug 包启动。"
echo ""
echo "· 请到屏幕「右上角菜单栏」点小人坐姿图标（或提醒时的拉伸图标）；"
echo "· 若没有：先试刘海旁的 「⋯」，在展开的菜单栏里找 SitWatcher；"
echo ""
echo "· 结束时可执行：killall SitWatcher"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 给用户一个可见的系统提示（不依赖是否已经打开勿扰）
osascript -e 'display notification "已到菜单栏启动；无 Dock — 请看右上角人像/坐姿图标" with title "SitWatcher"'
