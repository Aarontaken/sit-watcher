import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator?.startIfNeeded()
    }
}

@main
struct SitWatcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            if coordinator.showSettings {
                SettingsView(settings: coordinator.settings)
            } else {
                MenuBarPanel(
                    state: coordinator.appState,
                    onPauseToggle: coordinator.togglePause,
                    onSkip: coordinator.skip,
                    onReset: coordinator.reset,
                    onOpenSettings: { coordinator.showSettings = true },
                    onQuit: { NSApplication.shared.terminate(nil) }
                )
            }
        } label: {
            Image(systemName: menuBarIcon)
                .symbolEffect(.pulse, options: .repeating, isActive: coordinator.appState.reminderLevel == .l1)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: coordinator.started) {
            // triggers SwiftUI refresh when coordinator starts
        }
    }

    private var menuBarIcon: String {
        switch (coordinator.appState.timerPhase, coordinator.appState.reminderLevel) {
        case (.paused, _): return "figure.stand"
        case (.idle, _): return "figure.stand"
        case (_, .none): return "figure.stand"
        case (_, .l1): return "figure.walk"
        case (_, .l2): return "figure.walk"
        case (_, .l3): return "figure.run"
        }
    }

    init() {
        let coordinator = AppCoordinator()
        _coordinator = State(initialValue: coordinator)
        DispatchQueue.main.async {
            coordinator.startIfNeeded()
        }
    }
}
