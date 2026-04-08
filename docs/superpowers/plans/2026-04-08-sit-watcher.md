# SitWatcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that reminds users to stand up periodically, with progressive escalation from notification to fullscreen overlay.

**Architecture:** SwiftUI App lifecycle with `MenuBarExtra` for the menu bar panel. `NSWindow` for L2 floating reminder and L3 fullscreen overlay. Services layer (TimerEngine, IdleDetector, ReminderEscalator) are `@Observable` classes tested via XCTest.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit (NSWindow), macOS 14+, XCTest, xcodegen

---

## File Structure

```
SitWatcher/
├── project.yml                          # xcodegen project spec
├── SitWatcher/
│   ├── SitWatcherApp.swift              # App entry, MenuBarExtra scene
│   ├── AppState.swift                   # Central observable state
│   ├── Settings.swift                   # UserDefaults-backed settings
│   ├── Services/
│   │   ├── IdleDetector.swift           # Mouse/keyboard activity tracking
│   │   ├── TimerEngine.swift            # Countdown timer + idle integration
│   │   ├── ReminderEscalator.swift      # 3-level escalation state machine
│   │   └── NotificationManager.swift    # macOS notification wrapper
│   ├── Views/
│   │   ├── MenuBarPanel.swift           # Popover content (timer + controls + stats)
│   │   ├── TimerRingView.swift          # Circular gradient progress ring
│   │   ├── ControlButtonsView.swift     # Pause/Skip/Reset buttons
│   │   ├── StatsView.swift              # Today's stats display
│   │   ├── SettingsView.swift           # Settings form
│   │   ├── FloatingReminderView.swift   # L2 floating window content
│   │   └── FullScreenOverlayView.swift  # L3 overlay content
│   ├── Windows/
│   │   ├── FloatingWindowController.swift   # L2 NSWindow management
│   │   └── OverlayWindowController.swift    # L3 NSWindow management
│   ├── Resources/
│   │   └── Assets.xcassets/             # App icon
│   ├── Info.plist
│   └── SitWatcher.entitlements
├── SitWatcherTests/
│   ├── SettingsTests.swift
│   ├── IdleDetectorTests.swift
│   ├── TimerEngineTests.swift
│   └── ReminderEscalatorTests.swift
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`
- Create: `SitWatcher/Info.plist`
- Create: `SitWatcher/SitWatcher.entitlements`
- Create: `SitWatcher/SitWatcherApp.swift`
- Create: `SitWatcher/Resources/Assets.xcassets/Contents.json`
- Create: `SitWatcher/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Install xcodegen if needed**

Run: `brew list xcodegen || brew install xcodegen`
Expected: xcodegen available at command line.

- [ ] **Step 2: Create project.yml**

```yaml
# project.yml
name: SitWatcher
options:
  bundleIdPrefix: com.sitwatcher
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "15.0"
  minimumXcodeGenVersion: "2.35.0"

settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "14.0"

targets:
  SitWatcher:
    type: application
    platform: macOS
    sources:
      - SitWatcher
    settings:
      base:
        INFOPLIST_FILE: SitWatcher/Info.plist
        CODE_SIGN_ENTITLEMENTS: SitWatcher/SitWatcher.entitlements
        PRODUCT_BUNDLE_IDENTIFIER: com.sitwatcher.app
        GENERATE_INFOPLIST_FILE: false
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon

  SitWatcherTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - SitWatcherTests
    dependencies:
      - target: SitWatcher
    settings:
      base:
        BUNDLE_LOADER: "$(TEST_HOST)"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/SitWatcher.app/Contents/MacOS/SitWatcher"
```

- [ ] **Step 3: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>SitWatcher</string>
    <key>CFBundleDisplayName</key>
    <string>SitWatcher</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

`LSUIElement = true` hides the app from the Dock.

- [ ] **Step 4: Create entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

Sandbox disabled because we need `CGEventSource` access for idle detection and `NSWindow` level control for L3 overlay.

- [ ] **Step 5: Create Assets.xcassets structure**

`SitWatcher/Resources/Assets.xcassets/Contents.json`:
```json
{
  "info": { "version": 1, "author": "xcode" }
}
```

`SitWatcher/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images": [
    { "size": "128x128", "idiom": "mac", "scale": "1x" },
    { "size": "128x128", "idiom": "mac", "scale": "2x" },
    { "size": "256x256", "idiom": "mac", "scale": "1x" },
    { "size": "256x256", "idiom": "mac", "scale": "2x" },
    { "size": "512x512", "idiom": "mac", "scale": "1x" },
    { "size": "512x512", "idiom": "mac", "scale": "2x" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
```

- [ ] **Step 6: Create minimal SitWatcherApp.swift**

```swift
import SwiftUI

@main
struct SitWatcherApp: App {
    var body: some Scene {
        MenuBarExtra("SitWatcher", systemImage: "figure.stand") {
            Text("SitWatcher is running")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 7: Generate Xcode project and build**

Run:
```bash
cd /Users/wangzg/cursor-workspace/sit-watcher
xcodegen generate
xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build
```
Expected: Build succeeds. A menu bar icon appears when the app runs.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: scaffold SitWatcher macOS menu bar app"
```

---

### Task 2: Settings Model

**Files:**
- Create: `SitWatcher/Settings.swift`
- Create: `SitWatcherTests/SettingsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SitWatcherTests/SettingsTests.swift
import XCTest
@testable import SitWatcher

final class SettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-settings")!
        defaults.removePersistentDomain(forName: "test-settings")
        Settings.shared = Settings(defaults: defaults)
    }

    func testDefaultValues() {
        let s = Settings.shared
        XCTAssertEqual(s.reminderInterval, 30 * 60)
        XCTAssertEqual(s.l2Delay, 2 * 60)
        XCTAssertEqual(s.l3Delay, 2 * 60)
        XCTAssertEqual(s.idleThreshold, 5 * 60)
        XCTAssertEqual(s.mouseMovementThreshold, 10.0)
        XCTAssertTrue(s.soundEnabled)
        XCTAssertFalse(s.launchAtLogin)
    }

    func testPersistence() {
        let defaults = UserDefaults(suiteName: "test-persistence")!
        defaults.removePersistentDomain(forName: "test-persistence")
        let s = Settings(defaults: defaults)
        s.reminderInterval = 45 * 60
        s.soundEnabled = false

        let s2 = Settings(defaults: defaults)
        XCTAssertEqual(s2.reminderInterval, 45 * 60)
        XCTAssertFalse(s2.soundEnabled)

        defaults.removePersistentDomain(forName: "test-persistence")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: Compile error — `Settings` not defined.

- [ ] **Step 3: Implement Settings**

```swift
// SitWatcher/Settings.swift
import Foundation
import Observation
import ServiceManagement

@Observable
final class Settings {
    static var shared = Settings()

    private let defaults: UserDefaults

    var reminderInterval: TimeInterval {
        didSet { defaults.set(reminderInterval, forKey: "reminderInterval") }
    }

    var l2Delay: TimeInterval {
        didSet { defaults.set(l2Delay, forKey: "l2Delay") }
    }

    var l3Delay: TimeInterval {
        didSet { defaults.set(l3Delay, forKey: "l3Delay") }
    }

    var idleThreshold: TimeInterval {
        didSet { defaults.set(idleThreshold, forKey: "idleThreshold") }
    }

    var mouseMovementThreshold: Double {
        didSet { defaults.set(mouseMovementThreshold, forKey: "mouseMovementThreshold") }
    }

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let hasRun = defaults.bool(forKey: "hasRun")

        if hasRun {
            self.reminderInterval = defaults.double(forKey: "reminderInterval")
            self.l2Delay = defaults.double(forKey: "l2Delay")
            self.l3Delay = defaults.double(forKey: "l3Delay")
            self.idleThreshold = defaults.double(forKey: "idleThreshold")
            self.mouseMovementThreshold = defaults.double(forKey: "mouseMovementThreshold")
            self.soundEnabled = defaults.bool(forKey: "soundEnabled")
            self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        } else {
            self.reminderInterval = 30 * 60
            self.l2Delay = 2 * 60
            self.l3Delay = 2 * 60
            self.idleThreshold = 5 * 60
            self.mouseMovementThreshold = 10.0
            self.soundEnabled = true
            self.launchAtLogin = false
            defaults.set(true, forKey: "hasRun")
        }
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Settings model with UserDefaults persistence"
```

---

### Task 3: AppState

**Files:**
- Create: `SitWatcher/AppState.swift`

- [ ] **Step 1: Create AppState**

```swift
// SitWatcher/AppState.swift
import Foundation
import Observation

enum TimerPhase {
    case running
    case paused
    case idle
}

enum ReminderLevel: Int, Comparable {
    case none = 0
    case l1 = 1
    case l2 = 2
    case l3 = 3

    static func < (lhs: ReminderLevel, rhs: ReminderLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@Observable
final class AppState {
    var timerPhase: TimerPhase = .running
    var remainingSeconds: TimeInterval = 0
    var totalSeconds: TimeInterval = 0
    var reminderLevel: ReminderLevel = .none
    var snoozedThisCycle: Bool = false

    // daily stats
    var restCount: Int = 0
    var interruptCount: Int = 0
    var focusSeconds: TimeInterval = 0

    private var lastResetDate: Date = .now

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalSeconds)
    }

    var formattedTime: String {
        let mins = Int(remainingSeconds) / 60
        let secs = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var statusLabel: String {
        switch timerPhase {
        case .running: return reminderLevel == .none ? "专注中" : "提醒中"
        case .paused: return "已暂停"
        case .idle: return "已离开"
        }
    }

    func resetDailyStatsIfNeeded() {
        if !Calendar.current.isDateInToday(lastResetDate) {
            restCount = 0
            interruptCount = 0
            focusSeconds = 0
            lastResetDate = .now
        }
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add AppState observable model"
```

---

### Task 4: IdleDetector

**Files:**
- Create: `SitWatcher/Services/IdleDetector.swift`
- Create: `SitWatcherTests/IdleDetectorTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SitWatcherTests/IdleDetectorTests.swift
import XCTest
@testable import SitWatcher

final class IdleDetectorTests: XCTestCase {

    func testSmallMouseMovementIsIgnored() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 100, y: 100)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 105, y: 103))
        XCTAssertFalse(moved, "Movement of ~5.8px should be ignored (threshold=10)")
    }

    func testLargeMouseMovementIsDetected() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 100, y: 100)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 120, y: 100))
        XCTAssertTrue(moved, "Movement of 20px should be detected")
    }

    func testExactThresholdIsIgnored() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 0, y: 0)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 6, y: 8))
        XCTAssertFalse(moved, "Movement of exactly 10px should be ignored (< not <=)")
    }

    func testJustOverThresholdIsDetected() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 0, y: 0)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 7, y: 8))
        XCTAssertTrue(moved, "Movement of ~10.6px should be detected")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: Compile error — `IdleDetector` not defined.

- [ ] **Step 3: Implement IdleDetector**

```swift
// SitWatcher/Services/IdleDetector.swift
import Foundation
import CoreGraphics
import AppKit

@Observable
final class IdleDetector {
    var isUserIdle: Bool = false
    var lastMouseLocation: CGPoint = .zero

    private let mouseThreshold: Double
    private var idleAccumulator: TimeInterval = 0
    private var pollTimer: Timer?
    private let pollInterval: TimeInterval = 1.0

    var onIdleStateChanged: ((Bool) -> Void)?

    init(mouseThreshold: Double = 10.0) {
        self.mouseThreshold = mouseThreshold
    }

    func start(idleThreshold: TimeInterval) {
        lastMouseLocation = NSEvent.mouseLocation
        idleAccumulator = 0
        isUserIdle = false

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.tick(idleThreshold: idleThreshold)
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func isRealMouseMovement(to newLocation: CGPoint) -> Bool {
        let dx = newLocation.x - lastMouseLocation.x
        let dy = newLocation.y - lastMouseLocation.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance > mouseThreshold
    }

    private func tick(idleThreshold: TimeInterval) {
        let currentLocation = NSEvent.mouseLocation
        let keyboardIdle = CGEventSource.secondsSinceLastEventType(
            .hidSystemState, eventType: .keyDown
        )

        let hasRealMovement = isRealMouseMovement(to: currentLocation)
        let hasKeyboard = keyboardIdle < pollInterval * 2

        lastMouseLocation = currentLocation

        if hasRealMovement || hasKeyboard {
            idleAccumulator = 0
            if isUserIdle {
                isUserIdle = false
                onIdleStateChanged?(false)
            }
        } else {
            idleAccumulator += pollInterval
            if !isUserIdle && idleAccumulator >= idleThreshold {
                isUserIdle = true
                onIdleStateChanged?(true)
            }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add IdleDetector with mouse-threshold filtering"
```

---

### Task 5: TimerEngine

**Files:**
- Create: `SitWatcher/Services/TimerEngine.swift`
- Create: `SitWatcherTests/TimerEngineTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SitWatcherTests/TimerEngineTests.swift
import XCTest
@testable import SitWatcher

final class TimerEngineTests: XCTestCase {

    var state: AppState!
    var settings: Settings!
    var engine: TimerEngine!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-timer")!
        defaults.removePersistentDomain(forName: "test-timer")
        settings = Settings(defaults: defaults)
        settings.reminderInterval = 10 // 10 seconds for testing
        state = AppState()
        engine = TimerEngine(state: state, settings: settings)
    }

    override func tearDown() {
        engine.stop()
        super.tearDown()
    }

    func testInitialState() {
        engine.start()
        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 1)
        XCTAssertEqual(state.totalSeconds, 10)
    }

    func testPause() {
        engine.start()
        engine.pause()
        XCTAssertEqual(state.timerPhase, .paused)
    }

    func testResume() {
        engine.start()
        engine.pause()
        engine.resume()
        XCTAssertEqual(state.timerPhase, .running)
    }

    func testReset() {
        engine.start()
        state.remainingSeconds = 5
        engine.reset()
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 1)
        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.reminderLevel, .none)
        XCTAssertFalse(state.snoozedThisCycle)
    }

    func testSkip() {
        engine.start()
        state.remainingSeconds = 5
        engine.skip()
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 1)
        XCTAssertEqual(state.reminderLevel, .none)
    }

    func testTimerFiresCallback() {
        let expectation = expectation(description: "onTimerComplete called")
        engine.onTimerComplete = { expectation.fulfill() }
        engine.start()
        state.remainingSeconds = 0.5
        wait(for: [expectation], timeout: 3)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: Compile error — `TimerEngine` not defined.

- [ ] **Step 3: Implement TimerEngine**

```swift
// SitWatcher/Services/TimerEngine.swift
import Foundation

@Observable
final class TimerEngine {
    private let state: AppState
    private let settings: Settings
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0

    var onTimerComplete: (() -> Void)?

    init(state: AppState, settings: Settings) {
        self.state = state
        self.settings = settings
    }

    func start() {
        state.totalSeconds = settings.reminderInterval
        state.remainingSeconds = settings.reminderInterval
        state.timerPhase = .running
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        startTicking()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        state.timerPhase = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard state.timerPhase == .paused else { return }
        state.timerPhase = .running
        startTicking()
    }

    func reset() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        start()
    }

    func skip() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        start()
    }

    func enterIdle() {
        stop()
        state.timerPhase = .idle
    }

    func exitIdle() {
        start()
    }

    func snooze(duration: TimeInterval) {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = true
        state.totalSeconds = duration
        state.remainingSeconds = duration
        state.timerPhase = .running
        startTicking()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard state.timerPhase == .running else { return }

        state.remainingSeconds = max(0, state.remainingSeconds - tickInterval)
        state.focusSeconds += tickInterval
        state.resetDailyStatsIfNeeded()

        if state.remainingSeconds <= 0 && state.reminderLevel == .none {
            onTimerComplete?()
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add TimerEngine with pause/resume/reset/skip/snooze"
```

---

### Task 6: ReminderEscalator

**Files:**
- Create: `SitWatcher/Services/ReminderEscalator.swift`
- Create: `SitWatcher/Services/NotificationManager.swift`
- Create: `SitWatcherTests/ReminderEscalatorTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SitWatcherTests/ReminderEscalatorTests.swift
import XCTest
@testable import SitWatcher

final class ReminderEscalatorTests: XCTestCase {

    var state: AppState!
    var settings: Settings!
    var escalator: ReminderEscalator!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-escalator")!
        defaults.removePersistentDomain(forName: "test-escalator")
        settings = Settings(defaults: defaults)
        settings.l2Delay = 2
        settings.l3Delay = 2
        state = AppState()
        escalator = ReminderEscalator(state: state, settings: settings)
    }

    override func tearDown() {
        escalator.stop()
        super.tearDown()
    }

    func testStartBeginsAtL1() {
        escalator.start()
        XCTAssertEqual(state.reminderLevel, .l1)
    }

    func testEscalatesToL2() {
        let expectation = expectation(description: "L2 reached")
        escalator.onLevelChanged = { level in
            if level == .l2 { expectation.fulfill() }
        }
        escalator.start()
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(state.reminderLevel, .l2)
    }

    func testEscalatesToL3() {
        let expectation = expectation(description: "L3 reached")
        escalator.onLevelChanged = { level in
            if level == .l3 { expectation.fulfill() }
        }
        escalator.start()
        wait(for: [expectation], timeout: 8)
        XCTAssertEqual(state.reminderLevel, .l3)
    }

    func testDismissResetsLevel() {
        escalator.start()
        escalator.dismiss()
        XCTAssertEqual(state.reminderLevel, .none)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: Compile error — `ReminderEscalator` not defined.

- [ ] **Step 3: Implement NotificationManager**

```swift
// SitWatcher/Services/NotificationManager.swift
import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendReminder(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "SitWatcher"
        content.body = "已经坐了 \(minutes) 分钟了，起来活动一下吧 💪"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "sit-reminder-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func clearAll() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
```

- [ ] **Step 4: Implement ReminderEscalator**

```swift
// SitWatcher/Services/ReminderEscalator.swift
import Foundation

@Observable
final class ReminderEscalator {
    private let state: AppState
    private let settings: Settings
    private var escalationTimer: Timer?

    var onLevelChanged: ((ReminderLevel) -> Void)?

    init(state: AppState, settings: Settings) {
        self.state = state
        self.settings = settings
    }

    func start() {
        escalationTimer?.invalidate()
        setLevel(.l1)
        scheduleNextEscalation()
    }

    func stop() {
        escalationTimer?.invalidate()
        escalationTimer = nil
    }

    func dismiss() {
        stop()
        state.reminderLevel = .none
    }

    private func setLevel(_ level: ReminderLevel) {
        state.reminderLevel = level
        onLevelChanged?(level)
    }

    private func scheduleNextEscalation() {
        let delay: TimeInterval
        switch state.reminderLevel {
        case .none: return
        case .l1: delay = settings.l2Delay
        case .l2: delay = settings.l3Delay
        case .l3: return
        }

        escalationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.escalate()
        }
    }

    private func escalate() {
        switch state.reminderLevel {
        case .none: break
        case .l1:
            setLevel(.l2)
            scheduleNextEscalation()
        case .l2:
            setLevel(.l3)
            state.interruptCount += 1
        case .l3:
            break
        }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add ReminderEscalator and NotificationManager"
```

---

### Task 7: TimerRingView

**Files:**
- Create: `SitWatcher/Views/TimerRingView.swift`

- [ ] **Step 1: Create TimerRingView**

```swift
// SitWatcher/Views/TimerRingView.swift
import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let formattedTime: String
    let ringSize: CGFloat

    private let lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.29, green: 0.87, blue: 0.50),
                            Color(red: 0.13, green: 0.83, blue: 0.87)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            VStack(spacing: 2) {
                Text(formattedTime)
                    .font(.system(size: ringSize * 0.22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text("剩余时间")
                    .font(.system(size: ringSize * 0.08))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add TimerRingView circular progress component"
```

---

### Task 8: Menu Bar Panel

**Files:**
- Create: `SitWatcher/Views/ControlButtonsView.swift`
- Create: `SitWatcher/Views/StatsView.swift`
- Create: `SitWatcher/Views/MenuBarPanel.swift`

- [ ] **Step 1: Create ControlButtonsView**

```swift
// SitWatcher/Views/ControlButtonsView.swift
import SwiftUI

struct ControlButtonsView: View {
    let isPaused: Bool
    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            controlButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                label: isPaused ? "继续" : "暂停",
                action: onPauseToggle
            )
            controlButton(icon: "forward.end.fill", label: "跳过", action: onSkip)
            controlButton(icon: "arrow.counterclockwise", label: "重置", action: onReset)
        }
    }

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Create StatsView**

```swift
// SitWatcher/Views/StatsView.swift
import SwiftUI

struct StatsView: View {
    let restCount: Int
    let interruptCount: Int
    let focusSeconds: TimeInterval

    private var focusDisplay: String {
        let hours = Int(focusSeconds) / 3600
        let mins = (Int(focusSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours).\(mins / 6)h"
        }
        return "\(mins)min"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日统计")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack {
                statItem(value: "\(restCount)", label: "已休息", color: .green)
                Spacer()
                statItem(value: "\(interruptCount)", label: "被打断", color: .orange)
                Spacer()
                statItem(value: focusDisplay, label: "专注时长", color: .white)
            }
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 3: Create MenuBarPanel**

```swift
// SitWatcher/Views/MenuBarPanel.swift
import SwiftUI

struct MenuBarPanel: View {
    let state: AppState
    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            timerSection
            controlsSection
            Divider().padding(.horizontal, 20)
            statsSection
            footer
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text("SitWatcher")
                .font(.system(size: 15, weight: .bold))

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(state.statusLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var timerSection: some View {
        TimerRingView(
            progress: state.progress,
            formattedTime: state.formattedTime,
            ringSize: 140
        )
        .padding(.bottom, 20)
    }

    private var controlsSection: some View {
        ControlButtonsView(
            isPaused: state.timerPhase == .paused,
            onPauseToggle: onPauseToggle,
            onSkip: onSkip,
            onReset: onReset
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var statsSection: some View {
        StatsView(
            restCount: state.restCount,
            interruptCount: state.interruptCount,
            focusSeconds: state.focusSeconds
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        HStack {
            Button("⚙️ 设置", action: onOpenSettings)
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Button("退出", action: onQuit)
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.1))
    }

    private var statusColor: Color {
        switch (state.timerPhase, state.reminderLevel) {
        case (.paused, _): return .gray
        case (.idle, _): return .gray
        case (_, .none): return .green
        case (_, .l1): return .yellow
        case (_, .l2): return .orange
        case (_, .l3): return .red
        }
    }
}
```

- [ ] **Step 4: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add MenuBarPanel with timer ring, controls, and stats"
```

---

### Task 9: L2 Floating Window

**Files:**
- Create: `SitWatcher/Views/FloatingReminderView.swift`
- Create: `SitWatcher/Windows/FloatingWindowController.swift`

- [ ] **Step 1: Create FloatingReminderView**

```swift
// SitWatcher/Views/FloatingReminderView.swift
import SwiftUI

struct FloatingReminderView: View {
    let sittingMinutes: Int
    let canSnooze: Bool
    var onConfirm: () -> Void
    var onSnooze: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🧍‍♂️")
                .font(.system(size: 48))

            Text("该站起来了！")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("你已经连续坐了 \(sittingMinutes) 分钟")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button(action: onConfirm) {
                    Text("好的，我去活动")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.87, blue: 0.50),
                                    Color(red: 0.13, green: 0.83, blue: 0.87)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                if canSnooze {
                    Button(action: onSnooze) {
                        Text("稍后 5 分钟")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.09, blue: 0.16),
                    Color(red: 0.12, green: 0.16, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.4), radius: 20)
    }
}
```

- [ ] **Step 2: Create FloatingWindowController**

```swift
// SitWatcher/Windows/FloatingWindowController.swift
import AppKit
import SwiftUI

final class FloatingWindowController {
    private var window: NSWindow?

    func show(
        sittingMinutes: Int,
        canSnooze: Bool,
        onConfirm: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        close()

        let view = FloatingReminderView(
            sittingMinutes: sittingMinutes,
            canSnooze: canSnooze,
            onConfirm: { [weak self] in
                self?.close()
                onConfirm()
            },
            onSnooze: { [weak self] in
                self?.close()
                onSnooze()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.setFrameSize(hostingView.fittingSize)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        positionTopRight(window)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }

    private func positionTopRight(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - window.frame.width - 20
        let y = screenFrame.maxY - window.frame.height - 20
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add L2 floating reminder window"
```

---

### Task 10: L3 Fullscreen Overlay

**Files:**
- Create: `SitWatcher/Views/FullScreenOverlayView.swift`
- Create: `SitWatcher/Windows/OverlayWindowController.swift`

- [ ] **Step 1: Create FullScreenOverlayView**

```swift
// SitWatcher/Views/FullScreenOverlayView.swift
import SwiftUI

struct FullScreenOverlayView: View {
    let sittingMinutes: Int
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)

            RadialGradient(
                colors: [
                    Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.08),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )

            VStack(spacing: 24) {
                Text("🚶")
                    .font(.system(size: 64))

                Text("起来走走吧")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("已经坐了 \(sittingMinutes) 分钟，你的身体需要活动")
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)

                Button(action: onDismiss) {
                    Text("我已经站起来了")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.87, blue: 0.50),
                                    Color(red: 0.13, green: 0.83, blue: 0.87)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .ignoresSafeArea()
    }
}
```

- [ ] **Step 2: Create OverlayWindowController**

```swift
// SitWatcher/Windows/OverlayWindowController.swift
import AppKit
import SwiftUI

final class OverlayWindowController {
    private var windows: [NSWindow] = []

    func show(sittingMinutes: Int, onDismiss: @escaping () -> Void) {
        close()

        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen, sittingMinutes: sittingMinutes) {
                onDismiss()
            }
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func close() {
        windows.forEach { $0.close() }
        windows.removeAll()
    }

    private func createOverlayWindow(
        for screen: NSScreen,
        sittingMinutes: Int,
        onDismiss: @escaping () -> Void
    ) -> NSWindow {
        let view = FullScreenOverlayView(
            sittingMinutes: sittingMinutes,
            onDismiss: { [weak self] in
                self?.close()
                onDismiss()
            }
        )

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: view)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.setFrame(screen.frame, display: true)
        window.ignoresMouseEvents = false

        return window
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add L3 fullscreen overlay window"
```

---

### Task 11: Settings View

**Files:**
- Create: `SitWatcher/Views/SettingsView.swift`

- [ ] **Step 1: Create SettingsView**

```swift
// SitWatcher/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: Settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("设置")
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 16) {
                settingRow(
                    title: "提醒间隔",
                    value: "\(Int(settings.reminderInterval / 60)) 分钟"
                ) {
                    Slider(
                        value: $settings.reminderInterval,
                        in: (15 * 60)...(120 * 60),
                        step: 5 * 60
                    )
                }

                settingRow(
                    title: "L2 升级延迟",
                    value: "\(Int(settings.l2Delay / 60)) 分钟"
                ) {
                    Slider(value: $settings.l2Delay, in: 60...300, step: 30)
                }

                settingRow(
                    title: "L3 升级延迟",
                    value: "\(Int(settings.l3Delay / 60)) 分钟"
                ) {
                    Slider(value: $settings.l3Delay, in: 60...300, step: 30)
                }

                settingRow(
                    title: "Idle 阈值",
                    value: "\(Int(settings.idleThreshold / 60)) 分钟"
                ) {
                    Slider(value: $settings.idleThreshold, in: 60...600, step: 60)
                }

                settingRow(
                    title: "鼠标移动阈值",
                    value: "\(Int(settings.mouseMovementThreshold)) px"
                ) {
                    Slider(value: $settings.mouseMovementThreshold, in: 5...50, step: 5)
                }

                Divider()

                Toggle("提示音", isOn: $settings.soundEnabled)
                    .font(.system(size: 13))

                Toggle("开机自启动", isOn: $settings.launchAtLogin)
                    .font(.system(size: 13))
            }

            HStack {
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func settingRow<Content: View>(
        title: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 13))
                Spacer()
                Text(value)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            content()
        }
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add SettingsView with all configurable options"
```

---

### Task 12: Integration — Wire Everything Together

**Files:**
- Modify: `SitWatcher/SitWatcherApp.swift`

- [ ] **Step 1: Rewrite SitWatcherApp with full integration**

Replace `SitWatcher/SitWatcherApp.swift` with:

```swift
// SitWatcher/SitWatcherApp.swift
import SwiftUI

@main
struct SitWatcherApp: App {
    @State private var appState = AppState()
    @State private var settings = Settings.shared
    @State private var timerEngine: TimerEngine?
    @State private var idleDetector: IdleDetector?
    @State private var escalator: ReminderEscalator?
    @State private var showSettings = false

    private let floatingWindow = FloatingWindowController()
    private let overlayWindow = OverlayWindowController()

    var body: some Scene {
        MenuBarExtra {
            if showSettings {
                SettingsView(settings: settings)
            } else {
                MenuBarPanel(
                    state: appState,
                    onPauseToggle: togglePause,
                    onSkip: skip,
                    onReset: reset,
                    onOpenSettings: { showSettings = true },
                    onQuit: { NSApplication.shared.terminate(nil) }
                )
            }
        } label: {
            Image(systemName: menuBarIcon)
                .symbolEffect(.pulse, options: .repeating, isActive: appState.reminderLevel == .l1)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: showSettings) { _, newValue in
            if !newValue { /* returned from settings, no action needed */ }
        }
        .onAppear {
            setupEngine()
        }
    }

    private var menuBarIcon: String {
        switch (appState.timerPhase, appState.reminderLevel) {
        case (.paused, _): return "figure.stand"
        case (.idle, _): return "figure.stand"
        case (_, .none): return "figure.stand"
        case (_, .l1): return "figure.walk"
        case (_, .l2): return "figure.walk"
        case (_, .l3): return "figure.run"
        }
    }

    private func setupEngine() {
        NotificationManager.shared.requestPermission()

        let engine = TimerEngine(state: appState, settings: settings)
        let detector = IdleDetector(mouseThreshold: settings.mouseMovementThreshold)
        let esc = ReminderEscalator(state: appState, settings: settings)

        engine.onTimerComplete = { [esc] in
            let minutes = Int(settings.reminderInterval / 60)
            NotificationManager.shared.sendReminder(minutes: minutes)
            if settings.soundEnabled {
                NSSound(named: .init("Blow"))?.play()
            }
            esc.start()
        }

        esc.onLevelChanged = { [floatingWindow, overlayWindow] level in
            DispatchQueue.main.async {
                let minutes = Int(settings.reminderInterval / 60)
                switch level {
                case .none:
                    floatingWindow.close()
                    overlayWindow.close()
                    NotificationManager.shared.clearAll()
                case .l1:
                    break
                case .l2:
                    floatingWindow.show(
                        sittingMinutes: minutes,
                        canSnooze: !appState.snoozedThisCycle,
                        onConfirm: { confirmRest(engine: engine, escalator: esc) },
                        onSnooze: { snooze(engine: engine, escalator: esc) }
                    )
                case .l3:
                    floatingWindow.close()
                    overlayWindow.show(sittingMinutes: minutes) {
                        confirmRest(engine: engine, escalator: esc)
                    }
                }
            }
        }

        detector.onIdleStateChanged = { [engine] isIdle in
            DispatchQueue.main.async {
                if isIdle {
                    engine.enterIdle()
                    esc.dismiss()
                    floatingWindow.close()
                    overlayWindow.close()
                } else {
                    engine.exitIdle()
                }
            }
        }

        engine.start()
        detector.start(idleThreshold: settings.idleThreshold)

        self.timerEngine = engine
        self.idleDetector = detector
        self.escalator = esc
    }

    private func confirmRest(engine: TimerEngine, escalator: ReminderEscalator) {
        escalator.dismiss()
        floatingWindow.close()
        overlayWindow.close()
        NotificationManager.shared.clearAll()
        appState.restCount += 1
        engine.reset()
    }

    private func snooze(engine: TimerEngine, escalator: ReminderEscalator) {
        escalator.dismiss()
        floatingWindow.close()
        engine.snooze(duration: 5 * 60)
    }

    private func togglePause() {
        guard let engine = timerEngine else { return }
        if appState.timerPhase == .paused {
            engine.resume()
        } else {
            engine.pause()
        }
    }

    private func skip() {
        timerEngine?.skip()
    }

    private func reset() {
        timerEngine?.reset()
        escalator?.dismiss()
        floatingWindow.close()
        overlayWindow.close()
        NotificationManager.shared.clearAll()
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project SitWatcher.xcodeproj -scheme SitWatcherTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: integrate all components in SitWatcherApp"
```

---

### Task 13: Manual Smoke Test & Polish

- [ ] **Step 1: Build and run the app**

Run:
```bash
xcodebuild -project SitWatcher.xcodeproj -scheme SitWatcher -configuration Debug build
open /Users/wangzg/cursor-workspace/sit-watcher/build/Build/Products/Debug/SitWatcher.app
```

- [ ] **Step 2: Verify checklist**

Manually verify each behavior:
1. Menu bar icon appears (figure.stand icon)
2. Click icon → panel shows with timer counting down
3. Pause/Resume/Skip/Reset buttons work
4. When timer reaches 0 → system notification arrives
5. After 2 min ignoring → floating window appears at top-right
6. "稍后 5 分钟" delays and restarts from L1
7. After 2 more min ignoring → fullscreen overlay appears
8. "我已经站起来了" dismisses overlay and resets timer
9. Settings panel opens and values persist
10. Idle detection works (leave mouse still for 5+ min)

- [ ] **Step 3: Fix any issues found during smoke test**

Address any compilation or runtime issues discovered.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: polish and fix issues from smoke testing"
```

---

## Appendix: Key Technical Notes

**MenuBarExtra + NSWindow coexistence:** SwiftUI's `MenuBarExtra` handles the menu bar icon and popover panel. L2 and L3 windows are plain `NSWindow` instances managed by their own controllers. This hybrid approach gives us SwiftUI's declarative UI for the panel while retaining full control over window levels for the overlay.

**Window levels:**
- L2 floating window: `NSWindow.Level.floating` — above normal windows but below alerts
- L3 overlay: `NSWindow.Level.screenSaver` — above everything including the menu bar

**Idle detection polling:** 1-second polling interval is lightweight. `NSEvent.mouseLocation` is a simple property read (no event tap needed). `CGEventSource.secondsSinceLastEventType` is also a cheap system call. Combined CPU cost is negligible.

**@Observable vs ObservableObject:** We use Swift 5.9's `@Observable` macro (requires macOS 14+) instead of `ObservableObject`/`@Published`. This gives automatic fine-grained observation without boilerplate.
