import SwiftUI

/// Shared gradients & fills for MenuBar dropdowns, settings sheet, floating panels.
enum SitWatcherPanelChrome {
    static let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    static let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    static let peach = Color(red: 1.0, green: 0.55, blue: 0.45)

    static let deepIndigoTop = Color(red: 0.07, green: 0.05, blue: 0.20)
    static let deepIndigoBottom = Color(red: 0.04, green: 0.09, blue: 0.16)

    private static func borderGradient(for appearance: SitWatcherPanelAppearance) -> LinearGradient {
        LinearGradient(
            colors: appearance == .dark
                ? [mint.opacity(0.45), cyan.opacity(0.35), peach.opacity(0.4)]
                : [mint.opacity(0.38), cyan.opacity(0.24), peach.opacity(0.28)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    static func panelBackground(for appearance: SitWatcherPanelAppearance) -> some View {
        Group {
            switch appearance {
            case .dark:
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [deepIndigoTop, deepIndigoBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RadialGradient(
                        colors: [mint.opacity(0.12), cyan.opacity(0.05), .clear],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 200
                    )
                    RadialGradient(
                        colors: [peach.opacity(0.08), .clear],
                        center: .bottomTrailing,
                        startRadius: 2,
                        endRadius: 140
                    )
                }
            case .light, .system:
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.98, blue: 0.995),
                                    Color(red: 0.935, green: 0.94, blue: 0.955)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RadialGradient(
                        colors: [mint.opacity(0.13), cyan.opacity(0.04), .clear],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 190
                    )
                    RadialGradient(
                        colors: [peach.opacity(0.08), .clear],
                        center: .bottomTrailing,
                        startRadius: 2,
                        endRadius: 118
                    )
                }
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(borderGradient(for: appearance), lineWidth: 1)
        )
    }

    static func titleGradient(for appearance: SitWatcherPanelAppearance) -> LinearGradient {
        switch appearance {
        case .dark:
            LinearGradient(
                colors: [.white, mint.opacity(0.95)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .light, .system:
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.12, blue: 0.14),
                    mint.opacity(0.82)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    static func accentHairlineDivider(for appearance: SitWatcherPanelAppearance) -> LinearGradient {
        switch appearance {
        case .dark:
            LinearGradient(
                colors: [
                    Color.clear,
                    mint.opacity(0.35),
                    cyan.opacity(0.25),
                    peach.opacity(0.3),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .light, .system:
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.05),
                    mint.opacity(0.32),
                    Color.black.opacity(0.06),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    static func embossedCard(for appearance: SitWatcherPanelAppearance, cornerRadius: CGFloat = 12) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(appearance == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        appearance == .dark
                            ? LinearGradient(
                                colors: [mint.opacity(0.38), cyan.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    mint.opacity(0.28),
                                    cyan.opacity(0.16),
                                    Color.black.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: appearance == .dark ? Color.clear : Color.black.opacity(0.05),
                radius: appearance == .dark ? 0 : 4,
                y: appearance == .dark ? 0 : 1
            )
    }
}
