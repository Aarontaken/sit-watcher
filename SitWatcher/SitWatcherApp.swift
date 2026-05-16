import AppKit
import SwiftUI
import Sparkle

@main
struct SitWatcherApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        MenuBarExtra {
            ContentPanel(updater: updaterController)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

struct ContentPanel: View {
    let updater: SPUStandardUpdaterController

    @ObservedObject private var appState = AppCoordinator.shared.appState
    @ObservedObject private var settings = AppCoordinator.shared.settings

    private var coordinator: AppCoordinator { AppCoordinator.shared }

    var body: some View {
        if appState.showSettings {
            SettingsView(
                settings: settings,
                onBack: { appState.showSettings = false }
            )
        } else {
            MenuBarPanel(
                state: appState,
                onPauseToggle: { coordinator.togglePause() },
                onSkip: { coordinator.skip() },
                onReset: { coordinator.reset() },
                onTestReminder: { coordinator.testReminder() },
                onOpenSettings: { appState.showSettings = true },
                onCheckForUpdates: { updater.checkForUpdates(nil) },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        }
    }
}

private struct StretchReminderGlyph: View {
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var ticker = StretchFigureTicker()

    var body: some View {
        Group {
            if reduceMotion {
                Image(systemName: "figure.flexibility")
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(tint)
            } else {
                Image(systemName: ticker.useFlexibility ? "figure.flexibility" : "figure.cooldown")
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(tint)
            }
        }
        .onAppear {
            if reduceMotion == false {
                ticker.start()
            }
        }
        .onDisappear {
            ticker.stop()
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject private var appState = AppCoordinator.shared.appState

    var body: some View {
        Group {
            if shouldAnimateStretch {
                StretchReminderGlyph(tint: menuBarTint)
            } else {
                Image(systemName: "figure.seated.side.right")
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(menuBarTint)
            }
        }
        .frame(width: 18, height: 18)
        .fixedSize()
        .accessibilityLabel("SitWatcher")
    }

    private var shouldAnimateStretch: Bool {
        appState.reminderLevel != .none
    }

    /// Menu-bar extras stay template/monochrome; escalate urgency with tint only.
    private var menuBarTint: Color {
        if appState.timerPhase == .paused || appState.timerPhase == .idle {
            return Color.secondary
        }
        switch appState.reminderLevel {
        case .none:
            return Color.primary
        case .l1:
            return Color.primary
        case .l2:
            return Color.orange
        case .l3:
            return Color.red
        }
    }
}
