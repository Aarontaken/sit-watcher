import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let formattedTime: String
    let ringSize: CGFloat

    @ObservedObject private var localizationSettings = Settings.shared
    @Environment(\.sitWatcherPanelAppearance) private var appearance

    private let lineWidth: CGFloat = 8

    private let accentMint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let accentCyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let accentPeach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        let _ = localizationSettings.uiLanguage
        ZStack {
            Circle()
                .stroke(appearance.timerTrack, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [accentMint, accentCyan, accentPeach.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .shadow(color: accentMint.opacity(appearance == .dark ? 0.42 : 0.22), radius: 8, x: 0, y: 0)
                .shadow(color: accentCyan.opacity(appearance == .dark ? 0.28 : 0.14), radius: 4, x: 0, y: 2)

            RadialGradient(
                colors: [
                    accentMint.opacity(appearance == .dark ? 0.12 : 0.08),
                    accentCyan.opacity(appearance == .dark ? 0.06 : 0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: ringSize * 0.05,
                endRadius: ringSize * 0.38
            )

            VStack(spacing: 3) {
                Text(formattedTime)
                    .font(.system(size: ringSize * 0.24, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: appearance.timerDigitsGradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()

                Text(L10n.text("timer.remaining"))
                    .font(.system(size: ringSize * 0.08, weight: .medium))
                    .foregroundStyle(appearance.timerSubtitle)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}
