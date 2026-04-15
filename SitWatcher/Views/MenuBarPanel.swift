import SwiftUI

struct MenuBarPanel: View {
    @ObservedObject var state: AppState
    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void
    var onTestReminder: () -> Void
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            timerSection
            controlsSection
            Divider()
                .overlay(Color.white.opacity(0.06))
                .padding(.horizontal, 20)
            statsSection
            footer
        }
        .frame(width: 280)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            Text("SitWatcher")
                .font(.system(size: 15, weight: .bold))

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(state.statusLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var timerSection: some View {
        TimerRingView(
            progress: state.progress,
            formattedTime: state.formattedTime,
            ringSize: 140
        )
        .padding(.bottom, 20)
    }

    private var controlsSection: some View {
        ControlButtonsView(
            isPaused: state.timerPhase == .paused,
            onPauseToggle: onPauseToggle,
            onSkip: onSkip,
            onReset: onReset
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var statsSection: some View {
        StatsView(
            restCount: state.restCount,
            interruptCount: state.interruptCount,
            focusSeconds: state.focusSeconds
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        HStack {
            Button("⚙️ 设置", action: onOpenSettings)
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Button("🔔 测试", action: onTestReminder)
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Button("退出", action: onQuit)
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.1))
    }

    private var statusColor: Color {
        switch (state.timerPhase, state.reminderLevel) {
        case (.paused, _): return .gray
        case (.idle, _): return .gray
        case (_, .none): return .green
        case (_, .l1): return .yellow
        case (_, .l2): return .orange
        case (_, .l3): return .red
        }
    }
}
