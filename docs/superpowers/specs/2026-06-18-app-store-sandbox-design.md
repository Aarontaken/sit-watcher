# App Store Update and Sandbox Design

## Goal

Make SitWatcher a single Mac App Store distribution build. The app must no longer ship Sparkle or any self-update path, must enable App Sandbox, and must remain self-verifiable from the local workspace before App Store submission.

## Decisions

- Remove Sparkle from the only app target instead of maintaining separate App Store and direct-download variants.
- Replace "check for updates" with an App Store opener.
- Keep the App Store app ID in one small configuration point. Because the App Store Connect app record does not exist yet, the first implementation uses an empty placeholder and a deterministic fallback URL.
- Enable `com.apple.security.app-sandbox`.
- Add no extra sandbox entitlements unless verification proves an existing feature needs one.

## Update Flow

The footer update action becomes an App Store action:

1. If a numeric App Store app ID is configured, open `macappstore://apps.apple.com/app/id<APP_ID>`.
2. If that fails, open `https://apps.apple.com/app/id<APP_ID>`.
3. If no app ID is configured, open `https://apps.apple.com/search?term=SitWatcher`.

This flow never downloads, installs, or executes app code. It only sends the user to Apple-controlled App Store surfaces.

## Code Shape

- `project.yml`
  - Remove the Sparkle package declaration.
  - Remove the Sparkle target dependency from `SitWatcher`.
- `SitWatcher/Info.plist`
  - Remove `SUEnableAutomaticChecks`.
  - Remove `SUFeedURL`.
  - Remove `SUPublicEDKey`.
- `SitWatcher/SitWatcherApp.swift`
  - Remove `import Sparkle`.
  - Remove `SPUStandardUpdaterController`.
  - Remove `UpdateAvailabilityObserver`.
  - Keep the menu bar app composition intact.
  - Pass the new App Store opener action to the panel.
- New update-opening unit
  - Provide a small type such as `AppStoreUpdateOpener`.
  - Store the app ID placeholder in exactly one constant.
  - Expose a method that builds the attempted URLs without opening them, so unit tests can verify behavior without launching the App Store.
  - Expose a method that opens the URLs through an injectable closure, so tests can simulate success and failure.
- `SitWatcher/Views/UnifiedPanelPrototype.swift`
  - Keep the footer button location and icon pattern.
  - Rename the action concept from checking updates to opening the App Store.
  - Remove the available-update badge from this button, because the app no longer checks appcast metadata.
- Localized strings
  - Change the update footer label/help text from checking updates to opening the App Store.
  - Preserve unrelated local changes in `SitWatcher/Localizable.xcstrings`.
- `SitWatcher/SitWatcher.entitlements`
  - Set `com.apple.security.app-sandbox` to `true`.

## Sandbox Impact

Expected to keep working:

- Menu bar extra UI.
- AppKit/SwiftUI windows and overlays.
- `UserDefaults` settings.
- User notifications.
- Custom character imports from user-selected files, followed by storage under Application Support.
- Launch-at-login through `SMAppService.mainApp`.

Needs explicit verification:

- Idle detection through `NSEvent.mouseLocation`.
- Keyboard idle timing through `CGEventSource.secondsSinceLastEventType`.
- Full-screen overlay presentation across screens under sandbox.
- Custom character import from image, animated image, and video sources.

The implementation should not add broad file, automation, input monitoring, or accessibility entitlements preemptively. If a verification failure identifies a specific entitlement or user permission need, that should be handled as a targeted follow-up.

## Error Handling

- Opening App Store URLs should not block or crash the reminder workflow.
- If `macappstore://` opening reports failure, try HTTPS.
- If all open attempts fail, log a concise diagnostic with `print`.
- Missing App ID is not an error until the App Store record exists; it intentionally opens the search fallback.

## Verification Requirements

The implementation is only complete when it can be verified locally without relying on manual App Store submission.

Automated/static verification:

- `rg "Sparkle|SPU|SUFeedURL|SUPublicEDKey|SUEnableAutomaticChecks" SitWatcher project.yml` returns no production references.
- The generated Xcode project contains no Sparkle package dependency.
- `SitWatcher/SitWatcher.entitlements` has `com.apple.security.app-sandbox` set to `true`.
- Unit tests cover:
  - URL ordering when the App Store ID is configured.
  - Fallback search URL when the App Store ID is empty.
  - `macappstore://` failure followed by HTTPS success.
- Existing unit tests continue to pass with `xcodebuild test`.

Runtime verification:

- Generate the Xcode project with `xcodegen generate`.
- Build and test with the same local `xcodebuild test` flow already used by the project.
- Launch the debug app.
- Confirm the menu bar panel opens.
- Trigger the App Store footer action and verify the opener reaches the expected fallback URL while the App ID is empty.
- Confirm the app remains running after the action.
- Run a short sandbox smoke check for idle detection by observing that mouse/keyboard activity resets the idle accumulator and inactivity can still move toward idle.

## Out of Scope

- Creating the App Store Connect app record.
- Choosing pricing or subscription mechanics.
- App Store screenshots, metadata, and review notes.
- Reworking the reminder UX.
- Supporting both Sparkle and App Store builds at the same time.
