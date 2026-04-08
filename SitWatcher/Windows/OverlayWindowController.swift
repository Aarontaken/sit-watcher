import AppKit
import SwiftUI

private class InteractiveWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

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

        let window = InteractiveWindow(
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
        window.isMovableByWindowBackground = false

        return window
    }
}
