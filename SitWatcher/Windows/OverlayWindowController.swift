import AppKit
import SwiftUI

private class ClickablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class OverlayWindowController {
    private var panels: [NSPanel] = []

    func show(sittingMinutes: Int, onDismiss: @escaping () -> Void) {
        close()

        for screen in NSScreen.screens {
            let panel = createOverlayPanel(for: screen, sittingMinutes: sittingMinutes) {
                onDismiss()
            }
            panels.append(panel)
        }

        panels.first?.makeKeyAndOrderFront(nil)
    }

    func close() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }

    private func createOverlayPanel(
        for screen: NSScreen,
        sittingMinutes: Int,
        onDismiss: @escaping () -> Void
    ) -> NSPanel {
        let view = FullScreenOverlayView(
            sittingMinutes: sittingMinutes,
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
