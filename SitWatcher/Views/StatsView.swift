import SwiftUI

struct StatsView: View {
    let restCount: Int
    let interruptCount: Int
    let focusSeconds: TimeInterval

    @ObservedObject private var localizationSettings = Settings.shared
    @Environment(\.sitWatcherPanelAppearance) private var appearance

    private let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let peach = Color(red: 1.0, green: 0.55, blue: 0.45)
    private let violet = Color(red: 0.68, green: 0.55, blue: 1.0)

    private var focusDisplay: String {
        let hours = Int(focusSeconds) / 3600
        let mins = (Int(focusSeconds) % 3600) / 60
        if hours > 0 {
            return L10n.fmt("stats.focus_hours_fmt", hours, mins / 6)
        }
        return L10n.fmt("stats.focus_minutes_fmt", mins)
    }

    var body: some View {
        let _ = localizationSettings.uiLanguage
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [mint, violet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(L10n.text("stats.today"))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(appearance.primaryLabel.opacity(appearance == .dark ? 1.0 : 0.94))
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                statCard(
                    value: "\(restCount)",
                    label: L10n.text("stats.rest"),
                    icon: "cup.and.saucer.fill",
                    accent: mint
                )
                statCard(
                    value: "\(interruptCount)",
                    label: L10n.text("stats.interrupt"),
                    icon: "bolt.slash.fill",
                    accent: peach
                )
                statCard(
                    value: focusDisplay,
                    label: L10n.text("stats.focus"),
                    icon: "timer",
                    accent: violet
                )
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(accent.opacity(0.9))
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(appearance.statValueGradient(accent: accent))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(appearance.statLabelMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            SitWatcherPanelChrome.liquidSurface(
                for: appearance,
                cornerRadius: 12,
                accent: accent
            )
        )
    }
}
