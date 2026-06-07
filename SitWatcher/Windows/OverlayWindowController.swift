import AppKit
import SwiftUI

private class ClickablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class OverlayWindowController {
    private var panels: [NSPanel] = []
    /// Kept for legacy overlay compatibility; new overlay UI does not animate a shared glyph.
    private var sharedFullscreenFigureTicker: StretchFigureTicker?

    func show(sittingMinutes: Int, onDismiss: @escaping () -> Void) {
        close()

        let figureTicker = StretchFigureTicker()
        sharedFullscreenFigureTicker = figureTicker

        for screen in NSScreen.screens {
            let panel = createOverlayPanel(
                for: screen,
                sittingMinutes: sittingMinutes,
                figureTicker: figureTicker,
                onDismiss: onDismiss
            )
            panels.append(panel)
        }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion == false {
            figureTicker.start()
        }

        panels.first?.makeKeyAndOrderFront(nil)
    }

    func close() {
        sharedFullscreenFigureTicker?.stop()
        sharedFullscreenFigureTicker = nil
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }

    private func createOverlayPanel(
        for screen: NSScreen,
        sittingMinutes: Int,
        figureTicker: StretchFigureTicker,
        onDismiss: @escaping () -> Void
    ) -> NSPanel {
        let view = SitWatcherHostedFullScreenOverlay(
            sittingMinutes: sittingMinutes,
            figureTicker: figureTicker,
            onDismiss: { [weak self] in
                self?.close()
                onDismiss()
            }
        )

        let panel = ClickablePanel(
            contentRect: screen.frame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // Transparent fullscreen panels: AppKit keeps a cached *window* shadow shape; animated SwiftUI content inside
        // `NSHostingView` can leave a stale silhouette that looks like a second pose. Disable window shadows here.
        // See: https://stackoverflow.com/questions/79819793/how-to-get-rid-of-this-view-artifact-from-nshostingview-caused-by-when-the-swift
        panel.hasShadow = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = false
        panel.acceptsMouseMovedEvents = true
        panel.setFrame(screen.frame, display: true)
        panel.orderFrontRegardless()

        return panel
    }
}

private struct SitWatcherHostedFullScreenOverlay: View {
    let sittingMinutes: Int
    let figureTicker: StretchFigureTicker
    var onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var routingId: String {
        "\(Settings.shared.uiPanelAppearance.rawValue)-\(Settings.shared.uiPanelAppearance.resolvedPalette(for: colorScheme).rawValue)"
    }

    var body: some View {
        SitWatcherAppearanceScope(stored: Settings.shared.uiPanelAppearance) {
            RestReminderFullScreenView(
                sittingMinutes: sittingMinutes,
                onDismiss: onDismiss
            )
        }
        .environment(\.locale, Settings.shared.localizationLocale)
        .id(routingId)
    }
}
