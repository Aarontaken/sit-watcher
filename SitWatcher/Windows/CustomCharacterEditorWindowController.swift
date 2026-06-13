import AppKit
import SwiftUI

private final class CustomCharacterEditorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class CustomCharacterEditorWindowController {
    private var panel: NSPanel?

    var isVisible: Bool {
        panel?.isVisible == true
    }

    var currentPanelForTesting: NSPanel? {
        panel
    }

    func show(
        existingCharacter: CustomReminderCharacter?,
        language: UIAppLanguage,
        onComplete: @escaping (Result<CustomReminderCharacter, Error>) -> Void
    ) {
        close()

        let panel = makePanel(existingCharacter: existingCharacter, language: language, onComplete: onComplete)
        center(panel)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }

    func makePanelForTesting(
        existingCharacter: CustomReminderCharacter?,
        language: UIAppLanguage,
        onComplete: @escaping (Result<CustomReminderCharacter, Error>) -> Void
    ) -> NSPanel {
        makePanel(existingCharacter: existingCharacter, language: language, onComplete: onComplete)
    }

    private func makePanel(
        existingCharacter: CustomReminderCharacter?,
        language: UIAppLanguage,
        onComplete: @escaping (Result<CustomReminderCharacter, Error>) -> Void
    ) -> NSPanel {
        let view = CustomCharacterEditorView(
            existingCharacter: existingCharacter,
            language: language,
            onComplete: onComplete,
            onDismiss: { [weak self] in
                self?.close()
            }
        )
        let hostingView = NSHostingView(rootView: view)
        let panelSize = NSSize(width: 680, height: 540)
        hostingView.setFrameSize(panelSize)

        let panel = CustomCharacterEditorPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.contentMinSize = panelSize
        panel.contentMaxSize = panelSize
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .modalPanel
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        return panel
    }

    private func center(_ panel: NSPanel) {
        let screen = NSScreen.main
        let screenFrame = screen?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? .zero
        let size = panel.frame.size
        let centeredX = screenFrame.midX - size.width / 2
        let x = min(max(centeredX, screenFrame.minX + 12), screenFrame.maxX - size.width - 12)
        let centeredY = screenFrame.midY - size.height / 2
        let y = min(max(centeredY, screenFrame.minY + 12), screenFrame.maxY - size.height - 12)

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
