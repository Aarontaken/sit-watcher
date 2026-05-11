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

struct MenuBarLabel: View {
    @ObservedObject private var appState = AppCoordinator.shared.appState

    var body: some View {
        Image(systemName: iconName)
            .symbolEffect(.pulse, options: .repeating, isActive: appState.reminderLevel == .l1)
    }

    private var iconName: String {
        switch (appState.timerPhase, appState.reminderLevel) {
        case (.paused, _): return "figure.stand"
        case (.idle, _): return "figure.stand"
        case (_, .none): return "figure.stand"
        case (_, .l1): return "figure.walk"
        case (_, .l2): return "figure.walk"
        case (_, .l3): return "figure.run"
        }
    }
}
