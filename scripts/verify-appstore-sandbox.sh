#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPARKLE_CHECK_OUTPUT="${TMPDIR:-/tmp}/sitwatcher-sparkle-check.txt"

cd "$PROJECT_DIR"

echo "==> Generating Xcode project"
xcodegen generate -q

echo "==> Checking Sparkle was removed from production configuration"
if rg "Sparkle|XCRemoteSwiftPackageReference|SPU|SUAppcastItem|SUFeedURL|SUPublicEDKey|SUEnableAutomaticChecks" SitWatcher project.yml SitWatcher.xcodeproj >"$SPARKLE_CHECK_OUTPUT"; then
  cat "$SPARKLE_CHECK_OUTPUT"
  echo "Sparkle/self-update references remain" >&2
  exit 1
fi

echo "==> Checking sandbox entitlement"
/usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" SitWatcher/SitWatcher.entitlements | rg "^true$" >/dev/null
/usr/libexec/PlistBuddy -c "Print :com.apple.security.files.user-selected.read-only" SitWatcher/SitWatcher.entitlements | rg "^true$" >/dev/null

echo "==> Checking App Store opener fallback is covered by tests"
rg "testURLsUseSearchFallbackWhenAppIDIsEmpty|testOpenTriesHTTPSWhenMacAppStoreURLFails" SitWatcherTests/AppStoreUpdateOpenerTests.swift >/dev/null

echo "==> Running unit tests"
xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcher

echo "==> App Store sandbox verification passed"
