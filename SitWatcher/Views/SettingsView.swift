import AppKit
import SwiftUI

enum SettingsViewMetrics {
    /// Header row (`header`): back/title/icon row plus its bottom inset.
    static let headerBlockHeight: CGFloat = 78
    /// Done pill plus `padding(.top, 8)` on it.
    static let doneBlockHeight: CGFloat = 72

    /// Screen hosting the gesture (prefer cursor hit), then key/main window screen.
    static func sizingScreen() -> NSScreen? {
        let p = NSEvent.mouseLocation
        if let underMouse = NSScreen.screens.first(where: { NSMouseInRect(p, $0.frame, false) }) {
            return underMouse
        }
        if let windowScreen = (NSApp.keyWindow ?? NSApp.mainWindow)?.screen {
            return windowScreen
        }
        return NSScreen.main
    }

    /// When screen hit-testing misses, use tallest attached panel (better than collapsing the menu UX).
    private static func largestAttachedScreenHeight() -> CGFloat {
        NSScreen.screens.map(\.frame.height).max() ?? 900
    }

    /// 2/3 of logical screen height (`frame.height`) on sizing screen with safe fallbacks.
    static func panelTwoThirdsMaxHeight() -> CGFloat {
        if let height = sizingScreen()?.frame.height, height > 32 {
            return height * (2.0 / 3.0)
        }
        return largestAttachedScreenHeight() * (2.0 / 3.0)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @Environment(\.sitWatcherPanelAppearance) private var appearance
    var onBack: () -> Void
    var showsBackButton: Bool = true

    private var mint: Color { SitWatcherPanelChrome.mint }
    private var cyan: Color { SitWatcherPanelChrome.cyan }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                settingsFormContent
                    .frame(maxWidth: .infinity)
            }
            // Menu bar extra windows shrink to intrinsic min size; maxHeight alone never reserves space —
            // a fixed viewport height reliably grows the chrome + scroll slab so segments/cards aren't clipped.
            .frame(height: settingsFormMiddleHeight)

            Button(action: onBack) {
                Text(L10n.text("settings.done"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.88))
                    .frame(maxWidth: .infinity, minHeight: 40)
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
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .keyboardShortcut(.defaultAction)
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 318)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: SettingsViewMetrics.panelTwoThirdsMaxHeight(), alignment: .top)
        .background(SitWatcherPanelChrome.panelBackground(for: appearance))
    }

    private var settingsPanelChromeExcludingScroll: CGFloat {
        28
            + SettingsViewMetrics.headerBlockHeight
            + SettingsViewMetrics.doneBlockHeight
    }

    /// Exact scroll viewport (`frame(height:)`): panel cap − chrome clamped between sensible bounds.
    private var settingsFormMiddleHeight: CGFloat {
        let panelCap = SettingsViewMetrics.panelTwoThirdsMaxHeight()
        let raw = panelCap - settingsPanelChromeExcludingScroll
        return max(280, raw)
    }

    @ViewBuilder private var settingsFormContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            appearanceCard

            settingCard(
                title: L10n.text("settings.reminder_interval.title"),
                subtitle: L10n.text("settings.reminder_interval.subtitle"),
                value: L10n.fmt("settings.fmt.minutes", Int(settings.reminderInterval / 60))
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
                title: L10n.text("settings.fullscreen_delay.title"),
                subtitle: L10n.text("settings.fullscreen_delay.subtitle"),
                value: L10n.fmt("settings.fmt.minutes", Int(settings.l3Delay / 60))
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
                title: L10n.text("settings.idle.title"),
                subtitle: L10n.text("settings.idle.subtitle"),
                value: L10n.fmt("settings.fmt.minutes", Int(settings.idleThreshold / 60))
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
                title: L10n.text("settings.mouse.title"),
                subtitle: L10n.text("settings.mouse.subtitle"),
                value: L10n.fmt("settings.fmt.pixels", Int(settings.mouseMovementThreshold))
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

            languageCard
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    /// macOS skips hit-testing on fully transparent fills; tint is kept near-invisible while matching light/dark.
    private func segmentPillBackdropFill(isSelected: Bool) -> Color {
        if isSelected {
            return appearance.segmentSelectedBackdrop
        }
        switch appearance {
        case .dark:
            return Color.white.opacity(0.012)
        case .light, .system:
            return Color.black.opacity(0.018)
        }
    }

    private var switchesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            switchRow(
                title: L10n.text("settings.sound.title"),
                subtitle: L10n.text("settings.sound.subtitle"),
                isOn: Binding(
                    get: { settings.soundEnabled },
                    set: { settings.soundEnabled = $0 }
                )
            )

            Rectangle()
                .fill(appearance.hairlineMuted)
                .frame(height: 1)
                .padding(.leading, 4)
                .padding(.trailing, 4)

            switchRow(
                title: L10n.text("settings.launch_at_login.title"),
                subtitle: L10n.text("settings.launch_at_login.subtitle"),
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
                    .fill(appearance.switchesCardFill)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: appearance == .dark
                                ? [
                                    mint.opacity(0.52),
                                    cyan.opacity(0.32),
                                    SitWatcherPanelChrome.peach.opacity(0.35)
                                ]
                                : [
                                    mint.opacity(0.35),
                                    cyan.opacity(0.22),
                                    Color.black.opacity(0.06)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
            }
        }
        .shadow(color: appearance == .light ? Color.black.opacity(0.04) : Color.clear, radius: 6, y: 1)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text("settings.language.title"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(appearance.primaryLabel)
                Text(L10n.text("settings.language.subtitle"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(appearance.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 4) {
                ForEach(UIAppLanguage.allCases) { lang in
                    languageSegmentButton(lang: lang, isSelected: settings.uiLanguage == lang) {
                        settings.uiLanguage = lang
                    }
                }
            }
        }
        .padding(14)
        .background {
            SitWatcherPanelChrome.embossedCard(for: appearance, cornerRadius: 12)
        }
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text("settings.appearance.title"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(appearance.primaryLabel)
                Text(L10n.text("settings.appearance.subtitle"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(appearance.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                ForEach(SitWatcherPanelAppearance.allCases) { mode in
                    appearanceSegmentButton(
                        mode: mode,
                        isSelected: settings.uiPanelAppearance == mode
                    ) {
                        settings.uiPanelAppearance = mode
                    }
                }
            }
        }
        .padding(14)
        .background {
            SitWatcherPanelChrome.embossedCard(for: appearance, cornerRadius: 12)
        }
    }

    private func appearanceSegmentButton(
        mode: SitWatcherPanelAppearance,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(segmentPillBackdropFill(isSelected: isSelected))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                isSelected ? mint.opacity(appearance == .dark ? 0.45 : 0.32) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(mode.pickerCaption)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? appearance.segmentActiveLabel : appearance.segmentInactiveLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 40)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(mode.pickerCaption)
    }

    private func languageSegmentButton(
        lang: UIAppLanguage,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(segmentPillBackdropFill(isSelected: isSelected))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                isSelected ? mint.opacity(appearance == .dark ? 0.45 : 0.32) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(lang.pickerCaption)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? appearance.segmentActiveLabel : appearance.segmentInactiveLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 42)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(lang.pickerCaption)
    }

    private func switchRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(appearance.headlineLabel)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(appearance.tertiaryLabel)
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
            if showsBackButton {
                Button(action: onBack) {
                    Label(L10n.text("settings.back"), systemImage: "chevron.backward")
                        .font(.system(size: 12, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(appearance == .dark ? Color.white.opacity(0.78) : appearance.segmentInactiveLabel)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text("settings.window.title"))
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(SitWatcherPanelChrome.titleGradient(for: appearance))
                Text(L10n.text("settings.window.subtitle"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(appearance.secondaryLabel)
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
            .fill(SitWatcherPanelChrome.accentHairlineDivider(for: appearance))
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
                        .foregroundStyle(appearance.primaryLabel)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(appearance.secondaryLabel)
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
            SitWatcherPanelChrome.embossedCard(for: appearance, cornerRadius: 12)
        }
    }
}
