import SwiftUI

/// Locks `FloatingWindowController` frame (must cover hero slot + possible wrapped subtitle).
enum FloatingReminderPanelMetrics {
    static let width: CGFloat = 328
    /// Tight to content + small slack for wrapped subtitle; avoids large bottom gap without pushing buttons down.
    static let height: CGFloat = 348
}

struct FloatingReminderView: View {
    let sittingMinutes: Int
    let canSnooze: Bool
    var onConfirm: () -> Void
    var onSnooze: () -> Void

    @StateObject private var figureTicker = StretchFigureTicker()
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.sitWatcherPanelAppearance) private var appearance

    @ObservedObject private var localizationSettings = Settings.shared

    private let accentMint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let accentCyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let accentPeach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        let _ = localizationSettings.uiLanguage
        VStack(spacing: 20) {
            StretchReminderHeroFigure(ticker: figureTicker, size: 76)
                .padding(.top, 4)

            VStack(spacing: 8) {
                Text(L10n.text("floating.title"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(appearance.floatingTitleGradient)

                Text(L10n.fmt("floating.body_fmt", sittingMinutes))
                    .font(.system(size: 13))
                    .foregroundStyle(appearance.floatingBody)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text(L10n.text("floating.confirm_move"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [accentMint, accentCyan.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: accentMint.opacity(0.42), radius: 8, y: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                if canSnooze {
                    Button(action: onSnooze) {
                        Text(L10n.text("floating.snooze_fixed"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(appearance.floatingSnoozeForeground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(appearance.floatingSnoozeFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        accentCyan.opacity(appearance == .dark ? 0.45 : 0.32),
                                                        accentPeach.opacity(appearance == .dark ? 0.35 : 0.24)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(24)
        .frame(
            width: FloatingReminderPanelMetrics.width,
            height: FloatingReminderPanelMetrics.height,
            alignment: .top
        )
        .background {
            ZStack {
                SitWatcherPanelChrome.panelBackground(for: appearance)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: appearance == .dark
                                ? [
                                    accentMint.opacity(0.75),
                                    accentCyan.opacity(0.5),
                                    accentPeach.opacity(0.65)
                                ]
                                : [
                                    SitWatcherPanelChrome.mint.opacity(0.42),
                                    SitWatcherPanelChrome.cyan.opacity(0.3),
                                    SitWatcherPanelChrome.peach.opacity(0.34)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: appearance == .dark ? 1.5 : 1
                    )
            )
        }
        .onAppear {
            if accessibilityReduceMotion == false {
                figureTicker.start()
            }
        }
        .onDisappear {
            figureTicker.stop()
        }
    }
}
