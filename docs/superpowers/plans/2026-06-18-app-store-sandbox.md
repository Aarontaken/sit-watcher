# App Store Sandbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 SitWatcher 改成单一 Mac App Store 版本：移除 Sparkle 自更新、改为打开 App Store、启用 sandbox，并提供本地可执行验证。

**Architecture:** 新增一个小型 `AppStoreUpdateOpener` 服务集中管理 App Store ID、URL 构造和打开顺序；`SitWatcherApp` 只负责把 opener action 传给现有面板。构建配置删除 Sparkle，entitlements 开启 sandbox，验证脚本把静态检查和单元测试合在一起。

**Tech Stack:** Swift 5.9, SwiftUI/AppKit, XcodeGen, XCTest, shell scripts, ripgrep.

---

## 文件结构

- Create: `SitWatcher/AppStoreUpdateOpener.swift`
  - 负责 App Store app ID 配置、URL 构造、可注入 opener、fallback 顺序。
- Create: `SitWatcherTests/AppStoreUpdateOpenerTests.swift`
  - 覆盖 configured app ID、empty app ID fallback、失败后尝试 HTTPS。
- Create: `scripts/verify-appstore-sandbox.sh`
  - 运行 XcodeGen、静态 Sparkle 残留检查、entitlement 检查、Xcode project 依赖检查、`xcodebuild test`。
- Modify: `project.yml`
  - 删除 Sparkle package 和 target dependency。
- Modify: `SitWatcher/Info.plist`
  - 删除 `SUEnableAutomaticChecks`、`SUFeedURL`、`SUPublicEDKey`。
- Modify: `SitWatcher/SitWatcherApp.swift`
  - 删除 Sparkle import/controller/observer，改用 `AppStoreUpdateOpener`。
- Modify: `SitWatcher/Views/UnifiedPanelPrototype.swift`
  - footer action 命名从 updates/check 改为 App Store/open，移除红点参数与渲染。
- Modify: `SitWatcher/Localizable.xcstrings`
  - 将 `footer.updates` 的英文值改为 `App Store`，中文值改为 `商店`。修改前必须读取当前 diff，保留用户已有未提交改动。
- Modify: `SitWatcher/SitWatcher.entitlements`
  - 将 sandbox 从 `false` 改为 `true`。
- Modify generated: `SitWatcher.xcodeproj`
  - 由 `xcodegen generate` 生成，最终应不再包含 Sparkle package。

---

### Task 1: 为 App Store opener 写失败测试

**Files:**
- Create: `SitWatcherTests/AppStoreUpdateOpenerTests.swift`
- Later create: `SitWatcher/AppStoreUpdateOpener.swift`

- [ ] **Step 1: 写失败测试**

Create `SitWatcherTests/AppStoreUpdateOpenerTests.swift`:

```swift
import XCTest
@testable import SitWatcher

final class AppStoreUpdateOpenerTests: XCTestCase {
    func testURLsUseMacAppStoreThenHTTPSWhenAppIDIsConfigured() {
        let opener = AppStoreUpdateOpener(appID: "1234567890")

        XCTAssertEqual(opener.urlsToOpen().map(\.absoluteString), [
            "macappstore://apps.apple.com/app/id1234567890",
            "https://apps.apple.com/app/id1234567890",
        ])
    }

    func testURLsUseSearchFallbackWhenAppIDIsEmpty() {
        let opener = AppStoreUpdateOpener(appID: "")

        XCTAssertEqual(opener.urlsToOpen().map(\.absoluteString), [
            "https://apps.apple.com/search?term=SitWatcher",
        ])
    }

    func testOpenTriesHTTPSWhenMacAppStoreURLFails() {
        let opener = AppStoreUpdateOpener(appID: "1234567890")
        var opened: [String] = []

        let didOpen = opener.open { url in
            opened.append(url.absoluteString)
            return url.scheme == "https"
        }

        XCTAssertTrue(didOpen)
        XCTAssertEqual(opened, [
            "macappstore://apps.apple.com/app/id1234567890",
            "https://apps.apple.com/app/id1234567890",
        ])
    }

    func testOpenReturnsFalseWhenAllURLsFail() {
        let opener = AppStoreUpdateOpener(appID: "")
        var opened: [String] = []

        let didOpen = opener.open { url in
            opened.append(url.absoluteString)
            return false
        }

        XCTAssertFalse(didOpen)
        XCTAssertEqual(opened, [
            "https://apps.apple.com/search?term=SitWatcher",
        ])
    }
}
```

- [ ] **Step 2: 重新生成 Xcode project**

Run:

```bash
xcodegen generate
```

Expected: succeeds and includes the new test file in `SitWatcher.xcodeproj`.

- [ ] **Step 3: 运行测试确认失败**

Run:

```bash
xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcher -only-testing:SitWatcherTests/AppStoreUpdateOpenerTests
```

Expected: FAIL，错误包含 `Cannot find 'AppStoreUpdateOpener' in scope`。

---

### Task 2: 实现 AppStoreUpdateOpener

**Files:**
- Create: `SitWatcher/AppStoreUpdateOpener.swift`
- Test: `SitWatcherTests/AppStoreUpdateOpenerTests.swift`

- [ ] **Step 1: 添加最小实现**

Create `SitWatcher/AppStoreUpdateOpener.swift`:

```swift
import AppKit
import Foundation

struct AppStoreUpdateOpener {
    static let configuredAppID = ""

    private let appID: String
    private let searchTerm: String

    init(appID: String = Self.configuredAppID, searchTerm: String = "SitWatcher") {
        self.appID = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchTerm = searchTerm
    }

    func urlsToOpen() -> [URL] {
        if appID.isEmpty {
            return [
                URL(string: "https://apps.apple.com/search?term=\(Self.percentEncoded(searchTerm))")!
            ]
        }

        return [
            URL(string: "macappstore://apps.apple.com/app/id\(appID)")!,
            URL(string: "https://apps.apple.com/app/id\(appID)")!,
        ]
    }

    @discardableResult
    func open(using openURL: (URL) -> Bool = { NSWorkspace.shared.open($0) }) -> Bool {
        for url in urlsToOpen() {
            if openURL(url) {
                return true
            }
        }

        print("Failed to open App Store URL candidates: \(urlsToOpen().map(\.absoluteString))")
        return false
    }

    private static func percentEncoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
```

- [ ] **Step 2: 重新生成 Xcode project**

Run:

```bash
xcodegen generate
```

Expected: succeeds and includes `SitWatcher/AppStoreUpdateOpener.swift` in `SitWatcher.xcodeproj`.

- [ ] **Step 3: 运行 opener 测试确认通过**

Run:

```bash
xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcher -only-testing:SitWatcherTests/AppStoreUpdateOpenerTests
```

Expected: PASS。

- [ ] **Step 4: 提交 opener 和测试**

Run:

```bash
git add SitWatcher/AppStoreUpdateOpener.swift SitWatcherTests/AppStoreUpdateOpenerTests.swift SitWatcher.xcodeproj
git commit -m "feat: add app store update opener"
```

Expected: commit succeeds。

---

### Task 3: 从 app 接线中移除 Sparkle

**Files:**
- Modify: `SitWatcher/SitWatcherApp.swift`
- Modify: `SitWatcher/Views/UnifiedPanelPrototype.swift`

- [ ] **Step 1: 修改 `SitWatcherApp.swift`**

Replace the Sparkle-dependent top of `SitWatcher/SitWatcherApp.swift` with this shape:

```swift
import AppKit
import SwiftUI

@main
struct SitWatcherApp: App {
    private let appStoreUpdateOpener = AppStoreUpdateOpener()

    var body: some Scene {
        MenuBarExtra {
            ContentPanel(appStoreUpdateOpener: appStoreUpdateOpener)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

struct ContentPanel: View {
    let appStoreUpdateOpener: AppStoreUpdateOpener

    @ObservedObject private var appState = AppCoordinator.shared.appState
    @ObservedObject private var settings = AppCoordinator.shared.settings

    private var coordinator: AppCoordinator { AppCoordinator.shared }

    var body: some View {
        UnifiedPanelPrototype(
            state: appState,
            settings: settings,
            onPauseToggle: { coordinator.togglePause() },
            onSkip: { coordinator.skip() },
            onReset: { coordinator.reset() },
            onTestReminder: { coordinator.testReminder() },
            onOpenAppStore: { appStoreUpdateOpener.open() },
            onQuit: { NSApplication.shared.terminate(nil) }
        )
        .background(
            MenuBarWindowProbe { window in
                configureMenuWindow(window)
            }
        )
        .environment(\.locale, settings.localizationLocale)
    }
```

Delete the whole `UpdateAvailabilityObserver` type.

- [ ] **Step 2: 修改 `UnifiedPanelPrototype` 初始化参数**

In `SitWatcher/Views/UnifiedPanelPrototype.swift`, replace these stored properties:

```swift
let onCheckForUpdates: () -> Void
let hasAvailableUpdate: Bool
```

with:

```swift
let onOpenAppStore: () -> Void
```

Replace the footer button call:

```swift
smallFooterButton(
    icon: "arrow.triangle.2.circlepath",
    title: L10n.text("footer.updates"),
    showsBadge: hasAvailableUpdate,
    action: onCheckForUpdates
)
```

with:

```swift
smallFooterButton(
    icon: "arrow.up.forward.app",
    title: L10n.text("footer.updates"),
    action: onOpenAppStore
)
```

Keep `smallFooterButton(... showsBadge: Bool = false ...)` and `updateBadge` only if other code still uses it. If no code uses `showsBadge` or `updateBadge`, remove the parameter, badge block, animation value, and `updateBadge` property.

- [ ] **Step 3: 静态检查 Sparkle app 接线已消失**

Run:

```bash
rg "Sparkle|SPU|SUAppcastItem|UpdateAvailabilityObserver|onCheckForUpdates|hasAvailableUpdate" SitWatcher
```

Expected: no output.

- [ ] **Step 4: 运行已有测试**

Run:

```bash
xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcher
```

Expected: PASS, or compile failure only from project.yml still referencing Sparkle. If project.yml reference is the only failure, continue to Task 4.

---

### Task 4: 删除 Sparkle 构建配置、plist 配置并开启 sandbox

**Files:**
- Modify: `project.yml`
- Modify: `SitWatcher/Info.plist`
- Modify: `SitWatcher/SitWatcher.entitlements`
- Generated modify: `SitWatcher.xcodeproj`

- [ ] **Step 1: 修改 `project.yml`**

Remove this block:

```yaml
packages:
  Sparkle:
    url: https://github.com/sparkle-project/Sparkle
    from: "2.6.0"
```

Remove this target dependency:

```yaml
    dependencies:
      - package: Sparkle
```

- [ ] **Step 2: 修改 `Info.plist`**

Remove these keys and values:

```xml
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://Aarontaken.github.io/sit-watcher/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>WlDX2OYrBGjn79WHRHZmPRZt07CvRDpz2jizAIInAWM=</string>
```

- [ ] **Step 3: 开启 sandbox**

Change `SitWatcher/SitWatcher.entitlements` to:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: 重新生成 Xcode project**

Run:

```bash
xcodegen generate
```

Expected: succeeds.

- [ ] **Step 5: 检查 project 不再包含 Sparkle**

Run:

```bash
rg "Sparkle|XCRemoteSwiftPackageReference" SitWatcher.xcodeproj project.yml SitWatcher/Info.plist
```

Expected: no output.

- [ ] **Step 6: 提交构建配置迁移**

Run:

```bash
git add project.yml SitWatcher/Info.plist SitWatcher/SitWatcher.entitlements SitWatcher.xcodeproj
git commit -m "build: remove sparkle and enable sandbox"
```

Expected: commit succeeds。

---

### Task 5: 更新 footer 文案并保护用户本地改动

**Files:**
- Modify: `SitWatcher/Localizable.xcstrings`

- [ ] **Step 1: 查看用户已有改动**

Run:

```bash
git diff -- SitWatcher/Localizable.xcstrings
```

Expected: inspect output before editing. Do not discard unrelated changes.

- [ ] **Step 2: 只修改 `footer.updates` 的值**

Change `footer.updates` values to:

```json
"en" : {
  "stringUnit" : {
    "state" : "translated",
    "value" : "App Store"
  }
},
"zh-Hans" : {
  "stringUnit" : {
    "state" : "translated",
    "value" : "商店"
  }
}
```

- [ ] **Step 3: 确认 diff 只包含目标文案和用户原有改动**

Run:

```bash
git diff -- SitWatcher/Localizable.xcstrings
```

Expected: `footer.updates` values changed to `App Store` and `商店`; any pre-existing user changes remain.

- [ ] **Step 4: 提交本任务改动时只 stage 自己的 hunk**

Run one of:

```bash
git add -p SitWatcher/Localizable.xcstrings
```

or, if the file contains only our intended hunk plus already-user-approved hunk, stage carefully after reviewing:

```bash
git add SitWatcher/Localizable.xcstrings
```

Expected: user unrelated changes are not accidentally bundled unless they are the same hunk and cannot be separated cleanly.

- [ ] **Step 5: 提交文案更新**

Run:

```bash
git commit -m "chore: rename update footer for app store"
```

Expected: commit succeeds, or skip commit if staging would mix unrelated user changes in an unsafe way.

---

### Task 6: 添加一键验证脚本

**Files:**
- Create: `scripts/verify-appstore-sandbox.sh`

- [ ] **Step 1: 创建验证脚本**

Create `scripts/verify-appstore-sandbox.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "==> Generating Xcode project"
xcodegen generate -q

echo "==> Checking Sparkle was removed from production configuration"
if rg "Sparkle|XCRemoteSwiftPackageReference|SPU|SUAppcastItem|SUFeedURL|SUPublicEDKey|SUEnableAutomaticChecks" SitWatcher project.yml SitWatcher.xcodeproj >/tmp/sitwatcher-sparkle-check.txt; then
  cat /tmp/sitwatcher-sparkle-check.txt
  echo "Sparkle/self-update references remain" >&2
  exit 1
fi

echo "==> Checking sandbox entitlement"
/usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" SitWatcher/SitWatcher.entitlements | rg "^true$" >/dev/null

echo "==> Checking App Store opener fallback is covered by tests"
rg "testURLsUseSearchFallbackWhenAppIDIsEmpty|testOpenTriesHTTPSWhenMacAppStoreURLFails" SitWatcherTests/AppStoreUpdateOpenerTests.swift >/dev/null

echo "==> Running unit tests"
xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcher

echo "==> App Store sandbox verification passed"
```

- [ ] **Step 2: 设置可执行权限**

Run:

```bash
chmod +x scripts/verify-appstore-sandbox.sh
```

Expected: command succeeds.

- [ ] **Step 3: 运行脚本**

Run:

```bash
scripts/verify-appstore-sandbox.sh
```

Expected: exits 0 and prints `App Store sandbox verification passed`.

- [ ] **Step 4: 提交验证脚本**

Run:

```bash
git add scripts/verify-appstore-sandbox.sh
git commit -m "test: add app store sandbox verification"
```

Expected: commit succeeds。

---

### Task 7: 本地运行验证与 sandbox smoke test

**Files:**
- No required code changes.

- [ ] **Step 1: 运行一键验证**

Run:

```bash
scripts/verify-appstore-sandbox.sh
```

Expected: PASS。

- [ ] **Step 2: 启动 debug app**

Run:

```bash
bash scripts/run-debug-app.sh
```

Expected: Debug app launches, terminal explains menu bar icon location.

- [ ] **Step 3: 检查 sandbox entitlement 在构建产物中存在**

Run:

```bash
codesign -d --entitlements :- build/debug-derived/Build/Products/Debug/SitWatcher.app 2>/dev/null | plutil -extract com.apple.security.app-sandbox raw -
```

Expected: `true`。

- [ ] **Step 4: 运行 UI smoke check**

Manual interaction required but locally self-contained:

1. Open menu bar SitWatcher icon.
2. Confirm the panel opens without crash.
3. Click the footer App Store button.
4. Confirm the app remains running with `pgrep -fl SitWatcher`.
5. If Browser/App Store opens to search fallback, close it after checking.

Expected: panel opens, App Store/search fallback opens, app process remains alive.

- [ ] **Step 5: 运行 idle smoke check**

Manual/local observation:

1. In the app, set a very short reminder interval and idle threshold if needed.
2. Move mouse or press a key and confirm the app does not immediately treat the user as idle.
3. Stop input briefly and confirm the timer/reminder flow continues without sandbox-related crash.

Expected: no crash; idle/movement behavior remains plausible under sandbox. If behavior is blocked by system privacy, record the exact symptom before adding entitlements.

- [ ] **Step 6: 最终状态检查**

Run:

```bash
git status --short
```

Expected: only intentional changes remain. Do not revert user-owned `SitWatcher/Localizable.xcstrings` changes.

---

## 自检

- Spec coverage:
  - Sparkle 移除由 Tasks 3-4 覆盖。
  - App Store opener 和 App ID 空 fallback 由 Tasks 1-2 覆盖。
  - Sandbox 开启由 Task 4 覆盖。
  - 可自行验证由 Tasks 6-7 覆盖。
  - 用户本地化改动保护由 Task 5 覆盖。
- Placeholder scan: no TBD/TODO/fill-in steps; all code and commands are explicit.
- Type consistency:
  - `AppStoreUpdateOpener.urlsToOpen()` and `open(using:)` are defined before use.
  - `UnifiedPanelPrototype` receives `onOpenAppStore`.
  - Tests call the exact initializer and methods from Task 2.
