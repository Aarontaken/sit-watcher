import SwiftUI

struct ControlButtonsView: View {
    let isPaused: Bool
    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void

    private let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let peach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        HStack(spacing: 8) {
            controlButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                label: isPaused ? "继续" : "暂停",
                style: .accent,
                action: onPauseToggle
            )
            controlButton(
                icon: "forward.end.fill",
                label: "跳过",
                style: .softCyan,
                action: onSkip
            )
            controlButton(
                icon: "arrow.counterclockwise",
                label: "重置",
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
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(border(for: style), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: shadowColor(for: style), radius: style == .accent ? 10 : 6, y: 3)
            .foregroundStyle(foreground(for: style))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func background(for style: ControlStyle) -> some View {
        switch style {
        case .accent:
            LinearGradient(
                colors: [mint, cyan.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .softCyan:
            ZStack {
                Color.white.opacity(0.08)
                LinearGradient(colors: [cyan.opacity(0.12), Color.clear], startPoint: .top, endPoint: .bottom)
            }
        case .softPeach:
            ZStack {
                Color.white.opacity(0.07)
                LinearGradient(colors: [peach.opacity(0.14), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    private func border(for style: ControlStyle) -> Color {
        switch style {
        case .accent: return Color.white.opacity(0.18)
        case .softCyan: return cyan.opacity(0.28)
        case .softPeach: return peach.opacity(0.35)
        }
    }

    private func shadowColor(for style: ControlStyle) -> Color {
        switch style {
        case .accent: return mint.opacity(0.38)
        case .softCyan: return cyan.opacity(0.22)
        case .softPeach: return peach.opacity(0.26)
        }
    }

    private func foreground(for style: ControlStyle) -> Color {
        switch style {
        case .accent:
            return Color.black.opacity(0.88)
        case .softCyan, .softPeach:
            return Color.white.opacity(0.92)
        }
    }
}
