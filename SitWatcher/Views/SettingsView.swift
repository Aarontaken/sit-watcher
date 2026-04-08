import SwiftUI

struct SettingsView: View {
    @Bindable var settings: Settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("设置")
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 16) {
                settingRow(
                    title: "提醒间隔",
                    value: "\(Int(settings.reminderInterval / 60)) 分钟"
                ) {
                    Slider(
                        value: $settings.reminderInterval,
                        in: (15 * 60)...(120 * 60),
                        step: 5 * 60
                    )
                }

                settingRow(
                    title: "L2 升级延迟",
                    value: "\(Int(settings.l2Delay / 60)) 分钟"
                ) {
                    Slider(value: $settings.l2Delay, in: 60...300, step: 30)
                }

                settingRow(
                    title: "L3 升级延迟",
                    value: "\(Int(settings.l3Delay / 60)) 分钟"
                ) {
                    Slider(value: $settings.l3Delay, in: 60...300, step: 30)
                }

                settingRow(
                    title: "Idle 阈值",
                    value: "\(Int(settings.idleThreshold / 60)) 分钟"
                ) {
                    Slider(value: $settings.idleThreshold, in: 60...600, step: 60)
                }

                settingRow(
                    title: "鼠标移动阈值",
                    value: "\(Int(settings.mouseMovementThreshold)) px"
                ) {
                    Slider(value: $settings.mouseMovementThreshold, in: 5...50, step: 5)
                }

                Divider()

                Toggle("提示音", isOn: $settings.soundEnabled)
                    .font(.system(size: 13))

                Toggle("开机自启动", isOn: $settings.launchAtLogin)
                    .font(.system(size: 13))
            }

            HStack {
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func settingRow<Content: View>(
        title: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 13))
                Spacer()
                Text(value)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            content()
        }
    }
}
