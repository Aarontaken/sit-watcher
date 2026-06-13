import AppKit
import SwiftUI

private final class CustomCharacterDeleteConfirmationPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class CustomCharacterDeleteConfirmationWindowController {
    private var panel: NSPanel?

    func show(
        characterName: String,
        language: UIAppLanguage,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        close()

        let panel = makePanel(
            characterName: characterName,
            language: language,
            onConfirm: { [weak self] in
                self?.close()
                onConfirm()
            },
            onCancel: { [weak self] in
                self?.close()
                onCancel()
            }
        )
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
        characterName: String,
        language: UIAppLanguage,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> NSPanel {
        makePanel(characterName: characterName, language: language, onConfirm: onConfirm, onCancel: onCancel)
    }

    private func makePanel(
        characterName: String,
        language: UIAppLanguage,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> NSPanel {
        let view = CustomCharacterDeleteConfirmationView(
            characterName: characterName,
            language: language,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
        let hostingView = NSHostingView(rootView: view)
        let panelSize = NSSize(width: 420, height: 220)
        hostingView.setFrameSize(panelSize)

        let panel = CustomCharacterDeleteConfirmationPanel(
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
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    private func center(_ panel: NSPanel) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? .zero
        let size = panel.frame.size
        panel.setFrameOrigin(
            NSPoint(
                x: screenFrame.midX - size.width / 2,
                y: screenFrame.midY - size.height / 2
            )
        )
    }
}

private struct CustomCharacterDeleteConfirmationView: View {
    let characterName: String
    let language: UIAppLanguage
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.58, green: 0.11, blue: 0.11).opacity(0.14))
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(red: 0.62, green: 0.13, blue: 0.12))
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(text(chinese: "删除这个提醒角色？", english: "Delete this reminder character?"))
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(red: 0.14, green: 0.15, blue: 0.13))

                    Text(characterName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.48))
                        .lineLimit(1)
                }
            }

            Text(text(
                chinese: "删除后会移除导入文件和生成帧。如果当前正在使用这个角色，会切回默认线条角色。",
                english: "This removes the imported file and generated frames. If it is selected, SitWatcher will fall back to the line character."
            ))
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.black.opacity(0.56))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Spacer()

                Button(text(chinese: "取消", english: "Cancel")) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.62))
                .frame(height: 36)
                .padding(.horizontal, 14)

                Button {
                    onConfirm()
                } label: {
                    Label(text(chinese: "删除", english: "Delete"), systemImage: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .frame(height: 36)
                        .padding(.horizontal, 15)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
                .background {
                    Capsule(style: .continuous)
                        .fill(Color(red: 0.62, green: 0.13, blue: 0.12))
                        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
                }
            }
        }
        .padding(22)
        .frame(width: 420, height: 220)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.66), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func text(chinese: String, english: String) -> String {
        switch language {
        case .english:
            return english
        case .simplifiedChinese:
            return chinese
        case .system:
            return Locale.autoupdatingCurrent.language.languageCode?.identifier == "zh" ? chinese : english
        }
    }
}
