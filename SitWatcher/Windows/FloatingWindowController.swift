import AppKit
import SwiftUI

private class ClickablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
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

        let panel = ClickablePanel(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.hasShadow = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.acceptsMouseMovedEvents = true

        positionTopRight(panel)
        panel.orderFrontRegardless()

        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func positionTopRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - panel.frame.width - 20
        let y = screenFrame.maxY - panel.frame.height - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
