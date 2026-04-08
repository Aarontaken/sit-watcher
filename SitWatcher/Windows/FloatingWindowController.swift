import AppKit
import SwiftUI

final class FloatingWindowController {
    private var window: NSWindow?

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

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        positionTopRight(window)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }

    private func positionTopRight(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - window.frame.width - 20
        let y = screenFrame.maxY - window.frame.height - 20
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
