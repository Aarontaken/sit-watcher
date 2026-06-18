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

    private func configureMenuWindow(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView?.subviews.forEach { subview in
            subview.wantsLayer = true
            subview.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}

private struct MenuBarWindowProbe: NSViewRepresentable {
    var onWindowChange: (NSWindow?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard context.coordinator.window !== view.window else { return }
            context.coordinator.window = view.window
            onWindowChange(view.window)
        }
    }

    final class Coordinator {
        weak var window: NSWindow?
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
