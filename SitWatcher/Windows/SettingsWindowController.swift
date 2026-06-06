import AppKit
import SwiftUI

private class SettingsPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class SettingsWindowController {
    private var panel: NSPanel?

    var isVisible: Bool {
        panel?.isVisible == true
    }

    func show(anchorFrame: NSRect?) {
        if let panel {
            position(panel, anchorFrame: anchorFrame)
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SitWatcherHostedSettingsView { [weak self] in
            self?.close()
        }
        let hostingView = NSHostingView(rootView: view)
        let panelSize = NSSize(width: 350, height: SettingsViewMetrics.panelTwoThirdsMaxHeight())
        hostingView.setFrameSize(panelSize)
        configureGlassHost(hostingView)

        let panel = SettingsPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.contentMinSize = panelSize
        panel.contentMaxSize = panelSize
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        configureGlassPanel(panel)

        position(panel, anchorFrame: anchorFrame)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func position(_ panel: NSPanel, anchorFrame: NSRect?) {
        let screen = anchorFrame.flatMap { frame in
            NSScreen.screens.first { $0.frame.intersects(frame) }
        } ?? NSScreen.main
        let screenFrame = screen?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? .zero
        let size = panel.frame.size

        let centeredX = anchorFrame.map { $0.midX - size.width / 2 } ?? (screenFrame.maxX - size.width - 20)
        let x = min(max(centeredX, screenFrame.minX + 8), screenFrame.maxX - size.width - 8)
        let topY = anchorFrame.map { min($0.maxY, screenFrame.maxY) } ?? screenFrame.maxY
        let yFromAnchor = topY - size.height
        let y = min(max(yFromAnchor, screenFrame.minY + 8), screenFrame.maxY - size.height)

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func configureGlassPanel(_ panel: NSPanel) {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.cornerRadius = 18
        panel.contentView?.layer?.cornerCurve = .continuous
        panel.contentView?.layer?.masksToBounds = true
    }

    private func configureGlassHost(_ hostingView: NSHostingView<SitWatcherHostedSettingsView>) {
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.cornerRadius = 18
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
    }
}

private struct SitWatcherHostedSettingsView: View {
    var onClose: () -> Void

    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var colorScheme

    private var routingId: String {
        "\(settings.uiPanelAppearance.rawValue)-\(settings.uiPanelAppearance.resolvedPalette(for: colorScheme).rawValue)"
    }

    var body: some View {
        SitWatcherAppearanceScope(stored: settings.uiPanelAppearance) {
            SettingsView(settings: settings, onBack: onClose, showsBackButton: false)
        }
        .environment(\.locale, settings.localizationLocale)
        .id(routingId)
    }
}
