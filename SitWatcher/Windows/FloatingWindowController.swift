import AppKit
import SwiftUI

private class InteractivePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class FloatingWindowController {
    private var panel: NSPanel?

    func show(
        sittingMinutes: Int,
        canSnooze: Bool,
        onConfirm: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        close()

        let view = FloatingReminderView(
            sittingMinutes: sittingMinutes,
            canSnooze: canSnooze,
            onConfirm: { [weak self] in
                self?.close()
                onConfirm()
            },
            onSnooze: { [weak self] in
                self?.close()
                onSnooze()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = InteractivePanel(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = false

        positionTopRight(panel)
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }

    private func positionTopRight(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - window.frame.width - 20
        let y = screenFrame.maxY - window.frame.height - 20
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
