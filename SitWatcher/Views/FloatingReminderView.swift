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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, accentMint.opacity(0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(L10n.fmt("floating.body_fmt", sittingMinutes))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text(L10n.text("floating.confirm_move"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 20)
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
                }
                .buttonStyle(.plain)

                if canSnooze {
                    Button(action: onSnooze) {
                        Text(L10n.text("floating.snooze_fixed"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.82))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        accentCyan.opacity(0.45),
                                                        accentPeach.opacity(0.35)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
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
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.05, blue: 0.20),
                        Color(red: 0.04, green: 0.09, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        accentMint.opacity(0.24),
                        accentCyan.opacity(0.10),
                        accentPeach.opacity(0.04),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 8,
                    endRadius: 240
                )

                RadialGradient(
                    colors: [accentPeach.opacity(0.08), Color.clear],
                    center: .bottomTrailing,
                    startRadius: 4,
                    endRadius: 160
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accentMint.opacity(0.75),
                                accentCyan.opacity(0.5),
                                accentPeach.opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
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
