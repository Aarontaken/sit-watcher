import SwiftUI

struct ControlButtonsView: View {
    let isPaused: Bool
    @ObservedObject private var localizationSettings = Settings.shared
    @Environment(\.sitWatcherPanelAppearance) private var appearance

    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void

    private let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let peach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        let _ = localizationSettings.uiLanguage
        HStack(spacing: 8) {
            controlButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                label: isPaused ? L10n.text("controls.resume") : L10n.text("controls.pause"),
                style: .accent,
                action: onPauseToggle
            )
            controlButton(
                icon: "forward.end.fill",
                label: L10n.text("controls.skip"),
                style: .softCyan,
                action: onSkip
            )
            controlButton(
                icon: "arrow.counterclockwise",
                label: L10n.text("controls.reset"),
                style: .softPeach,
                action: onReset
            )
        }
    }

    private enum ControlStyle {
        case accent
        case softCyan
        case softPeach
    }

    private func controlButton(
        icon: String,
        label: String,
        style: ControlStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(background(for: style))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(border(for: style), lineWidth: style == .accent ? 1.2 : 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(appearance == .dark ? 0.18 : 0.7), lineWidth: 0.7)
                    .padding(1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: shadowColor(for: style), radius: style == .accent ? 10 : 6, y: 3)
            .foregroundStyle(foreground(for: style))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 52)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func background(for style: ControlStyle) -> some View {
        switch style {
        case .accent:
            ZStack {
                SitWatcherPanelChrome.liquidSurface(
                    for: appearance,
                    cornerRadius: 12,
                    accent: mint,
                    isProminent: true
                )
                LinearGradient(
                    colors: [
                        mint.opacity(appearance == .dark ? 0.72 : 0.68),
                        cyan.opacity(appearance == .dark ? 0.66 : 0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(appearance == .dark ? .screen : .multiply)
            }
        case .softCyan:
            SitWatcherPanelChrome.liquidSurface(
                for: appearance,
                cornerRadius: 12,
                accent: cyan
            )
        case .softPeach:
            SitWatcherPanelChrome.liquidSurface(
                for: appearance,
                cornerRadius: 12,
                accent: peach
            )
        }
    }

    private func border(for style: ControlStyle) -> Color {
        switch style {
        case .accent:
            appearance == .dark ? Color.white.opacity(0.24) : Color.white.opacity(0.72)
        case .softCyan:
            cyan.opacity(appearance == .dark ? 0.34 : 0.28)
        case .softPeach:
            peach.opacity(appearance == .dark ? 0.38 : 0.3)
        }
    }

    private func shadowColor(for style: ControlStyle) -> Color {
        switch style {
        case .accent: return mint.opacity(appearance == .dark ? 0.38 : 0.25)
        case .softCyan: return cyan.opacity(appearance == .dark ? 0.22 : 0.14)
        case .softPeach: return peach.opacity(appearance == .dark ? 0.26 : 0.18)
        }
    }

    private func foreground(for style: ControlStyle) -> Color {
        switch style {
        case .accent:
            return Color.black.opacity(0.88)
        case .softCyan, .softPeach:
            return appearance.controlMutedForeground
        }
    }
}
