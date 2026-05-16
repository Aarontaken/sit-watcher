import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    var onBack: () -> Void

    private let mint = SitWatcherPanelChrome.mint
    private let cyan = SitWatcherPanelChrome.cyan

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 14) {
                settingCard(
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
                    .tint(mint)
                }

                settingCard(
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
                    .tint(mint)
                }

                settingCard(
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
                    .tint(mint)
                }

                settingCard(
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
                    .tint(mint)
                }

                sectionHairline()

                switchesCard

                Button(action: onBack) {
                    Text("完成")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.88))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                colors: [mint, cyan.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: mint.opacity(0.35), radius: 8, y: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 6)
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 318)
        .fixedSize(horizontal: false, vertical: true)
        .background(SitWatcherPanelChrome.panelBackground)
        .preferredColorScheme(.dark)
    }

    private var switchesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            switchRow(
                title: "提示音",
                subtitle: "到点时播放简短提示（跟系统音量）",
                isOn: Binding(
                    get: { settings.soundEnabled },
                    set: { settings.soundEnabled = $0 }
                )
            )

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 4)
                .padding(.trailing, 4)

            switchRow(
                title: "开机自启动",
                subtitle: "登录后自动在菜单栏启动",
                isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                )
            )
        }
        .padding(12)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                mint.opacity(0.52),
                                cyan.opacity(0.32),
                                SitWatcherPanelChrome.peach.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
            }
        }
    }

    private func switchRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.96))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 16)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(mint)
                .scaleEffect(1.06)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onBack) {
                Label("返回", systemImage: "chevron.backward")
                    .font(.system(size: 12, weight: .semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("设置")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(SitWatcherPanelChrome.titleGradient)
                Text("按你的节奏改提醒")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.52))
            }

            Spacer(minLength: 0)

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [mint.opacity(0.92), cyan.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.bottom, 14)
    }

    private func sectionHairline() -> some View {
        Rectangle()
            .fill(SitWatcherPanelChrome.accentHairlineDivider)
            .frame(height: 1)
            .padding(.horizontal, 6)
            .opacity(0.9)
            .padding(.vertical, 4)
    }

    private func settingCard(
        title: String,
        subtitle: String,
        value: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.48))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [mint.opacity(0.95), cyan.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .monospacedDigit()
            }
            content()
        }
        .padding(14)
        .background {
            SitWatcherPanelChrome.embossedCard(cornerRadius: 12)
        }
    }
}
