import SwiftUI

/// Shared gradients & panel fill for MenuBar dropdown surfaces (矩形底 + 外层圆角由系统开窗提供).
enum SitWatcherPanelChrome {
    static let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    static let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    static let peach = Color(red: 1.0, green: 0.55, blue: 0.45)

    static let deepIndigoTop = Color(red: 0.07, green: 0.05, blue: 0.20)
    static let deepIndigoBottom = Color(red: 0.04, green: 0.09, blue: 0.16)

    static var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.white, mint.opacity(0.95)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var borderGradient: LinearGradient {
        LinearGradient(
            colors: [mint.opacity(0.45), cyan.opacity(0.35), peach.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentHairlineDivider: LinearGradient {
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
    }

    static var panelBackground: some View {
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
        .overlay(
            Rectangle()
                .strokeBorder(borderGradient, lineWidth: 1)
        )
    }

    /// Subtle bordered card matching stats / sliders on dark panels.
    static func embossedCard(cornerRadius: CGFloat = 12) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.065))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [mint.opacity(0.38), cyan.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
