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
        SitWatcherAppearanceScope(stored: settings.uiPanelAppearance) {
            AppearanceKeyedContent(
                updater: updater,
                settings: settings,
                appState: appState,
                coordinator: coordinator
            )
        }
    }
}

private struct AppearanceKeyedContent: View {
    let updater: SPUStandardUpdaterController
    @ObservedObject var settings: Settings
    @ObservedObject var appState: AppState
    let coordinator: AppCoordinator

    @Environment(\.colorScheme) private var colorScheme
    @State private var menuWindowFrame: NSRect?
    @State private var menuWindow: NSWindow?

    /// Omit language from `.id` so changing UI language doesn't replace this subtree (keeps ScrollView offset).
    private var routingId: String {
        "\(settings.uiPanelAppearance.rawValue)-\(settings.uiPanelAppearance.resolvedPalette(for: colorScheme).rawValue)"
    }

    var body: some View {
        MenuBarPanel(
            state: appState,
            onPauseToggle: { coordinator.togglePause() },
            onSkip: { coordinator.skip() },
            onReset: { coordinator.reset() },
            onTestReminder: { coordinator.testReminder() },
            onOpenSettings: {
                coordinator.openSettings(anchorFrame: menuWindowFrame, menuWindow: menuWindow)
            },
            onCheckForUpdates: { updater.checkForUpdates(nil) },
            onQuit: { NSApplication.shared.terminate(nil) }
        )
        .background(
            MenuBarWindowProbe { window in
                menuWindow = window
                menuWindowFrame = window?.frame
                if window?.isVisible == true {
                    coordinator.menuPanelDidAppear()
                }
            }
        )
        .environment(\.locale, settings.localizationLocale)
        .id(routingId)
    }
}

private struct MenuBarWindowProbe: NSViewRepresentable {
    var onWindowChange: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            onWindowChange(view.window)
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

    /// `figure.seated.side.right` only exists from macOS 15; Sonoma 14.x yields an empty menu-bar icon.
    private var menuBarSeatedFigureSymbol: String {
        if #available(macOS 15.0, *) {
            return "figure.seated.side.right"
        }
        return "figure.seated.side"
    }

    var body: some View {
        Group {
            if shouldAnimateStretch {
                StretchReminderGlyph(tint: menuBarTint)
            } else {
                Image(systemName: menuBarSeatedFigureSymbol)
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
