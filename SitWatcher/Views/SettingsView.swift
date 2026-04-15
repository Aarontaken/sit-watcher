import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("设置")
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 16) {
                settingRow(
                    title: "久坐提醒间隔",
                    subtitle: "每隔多久提醒你站起来",
                    value: "\(Int(settings.reminderInterval / 60)) 分钟"
                ) {
                    Slider(
                        value: Binding(
                            get: { settings.reminderInterval },
                            set: { settings.reminderInterval = $0 }
                        ),
                        in: (15 * 60)...(120 * 60),
                        step: 5 * 60
                    )
                }

                settingRow(
                    title: "全屏提醒延迟",
                    subtitle: "忽略浮窗多久后升级为全屏覆盖",
                    value: "\(Int(settings.l3Delay / 60)) 分钟"
                ) {
                    Slider(
                        value: Binding(
                            get: { settings.l3Delay },
                            set: { settings.l3Delay = $0 }
                        ),
                        in: 60...600,
                        step: 30
                    )
                }

                settingRow(
                    title: "离开检测时间",
                    subtitle: "多久没操作视为你已离开座位",
                    value: "\(Int(settings.idleThreshold / 60)) 分钟"
                ) {
                    Slider(
                        value: Binding(
                            get: { settings.idleThreshold },
                            set: { settings.idleThreshold = $0 }
                        ),
                        in: 60...600,
                        step: 60
                    )
                }

                settingRow(
                    title: "鼠标灵敏度",
                    subtitle: "低于此距离的鼠标移动会被忽略",
                    value: "\(Int(settings.mouseMovementThreshold)) px"
                ) {
                    Slider(
                        value: Binding(
                            get: { settings.mouseMovementThreshold },
                            set: { settings.mouseMovementThreshold = $0 }
                        ),
                        in: 5...50,
                        step: 5
                    )
                }

                Divider()

                Toggle("提示音", isOn: Binding(
                    get: { settings.soundEnabled },
                    set: { settings.soundEnabled = $0 }
                ))
                .font(.system(size: 13))

                Toggle("开机自启动", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                ))
                .font(.system(size: 13))
            }

            HStack {
                Spacer()
                Button("完成", action: onBack)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
        .preferredColorScheme(.dark)
    }

    private func settingRow<Content: View>(
        title: String,
        subtitle: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            content()
        }
    }
}
