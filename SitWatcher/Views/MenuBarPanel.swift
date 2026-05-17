import SwiftUI

struct MenuBarPanel: View {
    @ObservedObject var state: AppState
    @ObservedObject private var localizationSettings = Settings.shared
    @Environment(\.sitWatcherPanelAppearance) private var appearance

    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void
    var onTestReminder: () -> Void
    var onOpenSettings: () -> Void
    var onCheckForUpdates: () -> Void
    var onQuit: () -> Void

    var body: some View {
        let _ = localizationSettings.uiLanguage
        VStack(spacing: 0) {
            header
            timerSection
            controlsSection
            sectionDivider
            statsSection
            footer
        }
        .frame(width: 318)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SitWatcherPanelChrome.panelBackground(for: appearance))
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SitWatcher")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(SitWatcherPanelChrome.titleGradient(for: appearance))
                Text(L10n.text("menu.tagline"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(appearance.secondaryLabel)
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: statusColor.opacity(0.65), radius: 4)

                Text(state.statusLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(appearance.primaryLabel)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(appearance == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.045))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(statusColor.opacity(0.45), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(SitWatcherPanelChrome.accentHairlineDivider(for: appearance))
            .frame(height: 1)
            .padding(.horizontal, 22)
            .opacity(0.9)
            .padding(.vertical, 6)
    }

    private var timerSection: some View {
        TimerRingView(
            progress: state.progress,
            formattedTime: state.formattedTime,
            ringSize: 140
        )
        .padding(.bottom, 16)
    }

    private var controlsSection: some View {
        ControlButtonsView(
            isPaused: state.timerPhase == .paused,
            onPauseToggle: onPauseToggle,
            onSkip: onSkip,
            onReset: onReset
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    private var statsSection: some View {
        StatsView(
            restCount: state.restCount,
            interruptCount: state.interruptCount,
            focusSeconds: state.focusSeconds
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            footerItem(title: L10n.text("footer.settings"), systemImage: "gearshape", action: onOpenSettings)
            footerItem(title: L10n.text("footer.test"), systemImage: "waveform.path.ecg", action: onTestReminder)
            footerItem(title: L10n.text("footer.updates"), systemImage: "arrow.triangle.2.circlepath", action: onCheckForUpdates)
            footerItem(title: L10n.text("footer.quit"), systemImage: "rectangle.portrait.and.arrow.right", action: onQuit)
        }
        .font(.system(size: 10.5, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(appearance.footerBarFill)
        )
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func footerItem(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 10.5, weight: .medium))
                .imageScale(.small)
                .symbolRenderingMode(.monochrome)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(appearance.footerItemLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, minHeight: 32)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var statusColor: Color {
        switch (state.timerPhase, state.reminderLevel) {
        case (.paused, _), (.idle, _):
            return appearance.statusMuted
        case (_, .none):
            return SitWatcherPanelChrome.mint
        case (_, .l1):
            return Color(red: 0.96, green: 0.86, blue: 0.28)
        case (_, .l2):
            return SitWatcherPanelChrome.peach
        case (_, .l3):
            return Color(red: 1.0, green: 0.38, blue: 0.42)
        }
    }
}
