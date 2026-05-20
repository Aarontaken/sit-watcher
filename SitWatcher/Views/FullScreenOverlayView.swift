import SwiftUI

struct FullScreenOverlayView: View {
    let sittingMinutes: Int
    var onDismiss: () -> Void
    /// Observed only inside `StretchReminderHeroFigure`, not here — avoids invalidating the whole hosting tree each tick.
    let figureTicker: StretchFigureTicker
    @Environment(\.sitWatcherPanelAppearance) private var appearance

    @ObservedObject private var localizationSettings = Settings.shared

    private let accentMint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let accentCyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let accentPeach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        let _ = localizationSettings.uiLanguage
        ZStack {
            Color.black.opacity(appearance.fullscreenScrimOpacity)

            RadialGradient(
                colors: [
                    accentMint.opacity(appearance == .dark ? 0.16 : 0.12),
                    accentCyan.opacity(appearance == .dark ? 0.06 : 0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )

            RadialGradient(
                colors: [accentPeach.opacity(appearance == .dark ? 0.08 : 0.06), Color.clear],
                center: UnitPoint(x: 0.15, y: 0.85),
                startRadius: 20,
                endRadius: 300
            )

            VStack(spacing: 24) {
                StretchReminderHeroFigure(
                    ticker: figureTicker,
                    size: 112,
                    shadowProfile: .fullscreenFlat,
                    glyphSwapStyle: .dualOpacityLayers
                )
                Text(L10n.text("fullscreen.title"))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(appearance.fullscreenTitleGradient)

                Text(L10n.fmt("fullscreen.body_fmt", sittingMinutes))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(appearance.fullscreenSubtitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onDismiss) {
                    Text(L10n.text("fullscreen.dismiss_button"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black.opacity(0.88))
                        .frame(minWidth: 220, minHeight: 46)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [
                                    accentMint,
                                    accentCyan.opacity(0.9),
                                    accentPeach.opacity(0.82)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accentMint.opacity(0.45), radius: 16, y: 5)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .ignoresSafeArea()
    }
}
