import SwiftUI

@main
struct SitWatcherApp: App {
    let coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            ContentPanel(coordinator: coordinator)
        } label: {
            MenuBarLabel(appState: coordinator.appState)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        DispatchQueue.main.async { [coordinator] in
            coordinator.start()
        }
    }
}

struct ContentPanel: View {
    let coordinator: AppCoordinator

    var body: some View {
        if coordinator.appState.showSettings {
            SettingsView(settings: coordinator.settings)
        } else {
            MenuBarPanel(
                state: coordinator.appState,
                onPauseToggle: coordinator.togglePause,
                onSkip: coordinator.skip,
                onReset: coordinator.reset,
                onOpenSettings: { coordinator.appState.showSettings = true },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        }
    }
}

struct MenuBarLabel: View {
    let appState: AppState

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
