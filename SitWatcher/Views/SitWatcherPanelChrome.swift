import SwiftUI

/// Shared gradients & fills for MenuBar dropdowns, settings sheet, floating panels.
enum SitWatcherPanelChrome {
    static let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    static let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    static let peach = Color(red: 1.0, green: 0.55, blue: 0.45)
    static let violet = Color(red: 0.68, green: 0.55, blue: 1.0)

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

    @ViewBuilder
    static func liquidPanelBackground(for appearance: SitWatcherPanelAppearance) -> some View {
        liquidPanelBackground(for: appearance, edgeHighlights: true)
    }

    @ViewBuilder
    static func quietLiquidPanelBackground(for appearance: SitWatcherPanelAppearance) -> some View {
        liquidPanelBackground(for: appearance, edgeHighlights: false)
            .opacity(0.92)
    }

    @ViewBuilder
    private static func liquidPanelBackground(
        for appearance: SitWatcherPanelAppearance,
        edgeHighlights: Bool
    ) -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: appearance == .dark
                            ? [
                                Color(red: 0.045, green: 0.055, blue: 0.075).opacity(edgeHighlights ? 0.24 : 0.18),
                                Color(red: 0.055, green: 0.075, blue: 0.09).opacity(edgeHighlights ? 0.14 : 0.1),
                                Color(red: 0.025, green: 0.03, blue: 0.045).opacity(edgeHighlights ? 0.22 : 0.16)
                            ]
                            : [
                                Color.white.opacity(edgeHighlights ? 0.14 : 0.09),
                                Color(red: 0.93, green: 0.975, blue: 0.965).opacity(edgeHighlights ? 0.07 : 0.04),
                                Color(red: 0.965, green: 0.955, blue: 0.985).opacity(edgeHighlights ? 0.1 : 0.06)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(
                                appearance == .dark
                                    ? (edgeHighlights ? 0.09 : 0.055)
                                    : (edgeHighlights ? 0.18 : 0.1)
                            ),
                            Color.white.opacity(0.02),
                            cyan.opacity(appearance == .dark ? (edgeHighlights ? 0.035 : 0.025) : (edgeHighlights ? 0.04 : 0.026)),
                            peach.opacity(appearance == .dark ? (edgeHighlights ? 0.025 : 0.018) : (edgeHighlights ? 0.032 : 0.022))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(appearance == .dark ? .screen : .softLight)

            if edgeHighlights {
                VStack(spacing: 0) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(appearance == .dark ? 0.05 : 0.14))
                        .frame(height: 1)
                        .padding(.horizontal, 28)
                        .padding(.top, 1)
                    Spacer()
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(appearance == .dark ? 0.03 : 0.01))
                        .frame(height: 1)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 1)
                }
            }
        }
    }

    static func liquidSurface(
        for appearance: SitWatcherPanelAppearance,
        cornerRadius: CGFloat = 12,
        accent: Color? = nil,
        isProminent: Bool = false,
        isQuiet: Bool = false
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: liquidSurfaceFillColors(
                                for: appearance,
                                accent: accent,
                                isProminent: isProminent,
                                isQuiet: isQuiet
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: liquidSurfaceStrokeColors(for: appearance, accent: accent, isQuiet: isQuiet),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isQuiet ? 0.55 : (isProminent ? 1.25 : 1)
                    )
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.white.opacity(
                            appearance == .dark
                                ? (isQuiet ? 0.08 : 0.16)
                                : (isQuiet ? 0.28 : 0.62)
                        ),
                        lineWidth: isQuiet ? 0.45 : 0.7
                    )
                    .blur(radius: 0.2)
                    .padding(1)
            }
            .shadow(
                color: (accent ?? Color.black).opacity(
                    isQuiet
                        ? (appearance == .dark ? 0.055 : 0.035)
                        : (
                            isProminent
                                ? (appearance == .dark ? 0.24 : 0.16)
                                : (appearance == .dark ? 0.12 : 0.08)
                        )
                ),
                radius: isQuiet ? 5 : (isProminent ? 12 : 7),
                y: isQuiet ? 2 : (isProminent ? 5 : 3)
            )
    }

    private static func liquidSurfaceFillColors(
        for appearance: SitWatcherPanelAppearance,
        accent: Color?,
        isProminent: Bool,
        isQuiet: Bool
    ) -> [Color] {
        let accent = accent ?? cyan
        switch appearance {
        case .dark:
            return [
                Color.white.opacity(isQuiet ? 0.055 : (isProminent ? 0.16 : 0.1)),
                accent.opacity(isQuiet ? 0.045 : (isProminent ? 0.2 : 0.08)),
                Color.white.opacity(isQuiet ? 0.025 : (isProminent ? 0.08 : 0.045))
            ]
        case .light, .system:
            return [
                Color.white.opacity(isQuiet ? 0.42 : (isProminent ? 0.78 : 0.62)),
                accent.opacity(isQuiet ? 0.04 : (isProminent ? 0.18 : 0.08)),
                Color.white.opacity(isQuiet ? 0.32 : (isProminent ? 0.42 : 0.5))
            ]
        }
    }

    private static func liquidSurfaceStrokeColors(
        for appearance: SitWatcherPanelAppearance,
        accent: Color?,
        isQuiet: Bool
    ) -> [Color] {
        let accent = accent ?? cyan
        switch appearance {
        case .dark:
            return [
                Color.white.opacity(isQuiet ? 0.12 : 0.3),
                accent.opacity(isQuiet ? 0.14 : 0.32),
                Color.white.opacity(isQuiet ? 0.035 : 0.08)
            ]
        case .light, .system:
            return [
                Color.white.opacity(isQuiet ? 0.46 : 0.92),
                accent.opacity(isQuiet ? 0.12 : 0.28),
                Color.black.opacity(isQuiet ? 0.025 : 0.07)
            ]
        }
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
