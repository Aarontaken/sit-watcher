import SwiftUI

struct MenuBarPanel: View {
    @ObservedObject var state: AppState
    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void
    var onTestReminder: () -> Void
    var onOpenSettings: () -> Void
    var onCheckForUpdates: () -> Void
    var onQuit: () -> Void

    var body: some View {
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
        .background(SitWatcherPanelChrome.panelBackground)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SitWatcher")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(SitWatcherPanelChrome.titleGradient)
                Text("久坐也要透口气 ✨")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.52))
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: statusColor.opacity(0.65), radius: 4)

                Text(state.statusLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.09))
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
            .fill(SitWatcherPanelChrome.accentHairlineDivider)
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
            footerItem(title: "设置", systemImage: "gearshape", action: onOpenSettings)
            footerItem(title: "测试", systemImage: "waveform.path.ecg", action: onTestReminder)
            footerItem(title: "更新", systemImage: "arrow.triangle.2.circlepath", action: onCheckForUpdates)
            footerItem(title: "退出", systemImage: "rectangle.portrait.and.arrow.right", action: onQuit)
        }
        .font(.system(size: 10.5, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.06))
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
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch (state.timerPhase, state.reminderLevel) {
        case (.paused, _), (.idle, _):
            return Color.white.opacity(0.45)
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
