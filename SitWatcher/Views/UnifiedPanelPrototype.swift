import SwiftUI

struct UnifiedPanelPrototype: View {
    @ObservedObject var state: AppState
    @ObservedObject var settings: Settings

    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void
    var onTestReminder: () -> Void
    var onCheckForUpdates: () -> Void
    var hasAvailableUpdate: Bool = false
    var onQuit: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: UnifiedPanelTab = .timer
    @State private var customCharacters: [CustomReminderCharacter] = []
    @State private var isShowingCharacterImporter = false
    @State private var editingCharacter: CustomReminderCharacter?
    @State private var characterErrorMessage: String?
    private let customCharacterStore = CustomCharacterStore()

    private var palette: UnifiedPanelPalette {
        UnifiedPanelPalette(theme: settings.unifiedPanelTheme, scheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            tabStrip
                .padding(.top, 18)

            ZStack(alignment: .top) {
                timerPane
                    .opacity(selectedTab == .timer ? 1 : 0)
                    .allowsHitTesting(selectedTab == .timer)
                    .accessibilityHidden(selectedTab != .timer)

                settingsPane
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(selectedTab == .settings)
                    .accessibilityHidden(selectedTab != .settings)
            }
            .animation(.easeOut(duration: 0.16), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 22)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .frame(width: 382, height: 620)
        .background(panelBackground)
        .environment(\.locale, settings.localizationLocale)
        .onAppear(perform: reloadCustomCharacters)
        .sheet(isPresented: $isShowingCharacterImporter) {
            CustomCharacterEditorView(existingCharacter: nil) { result in
                handleCharacterEditorResult(result)
            }
        }
        .sheet(item: $editingCharacter) { character in
            CustomCharacterEditorView(existingCharacter: character) { result in
                handleCharacterEditorResult(result)
            }
        }
        .alert(characterErrorTitle, isPresented: characterErrorBinding) {
            Button("OK", role: .cancel) {
                characterErrorMessage = nil
            }
        } message: {
            Text(characterErrorMessage ?? "")
        }
    }

    private var panelBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: palette.backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("SitWatcher")
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.title)

                Text(statusCaption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                statusDot

                Text(state.statusLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(palette.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(palette.recessedFill)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(palette.subtleStroke, lineWidth: 1)
            }
        }
    }

    private var tabStrip: some View {
        HStack(spacing: 4) {
            tabButton(.timer, icon: "timer", title: localized(chinese: "计时", english: "Timer"))
            tabButton(.settings, icon: "slider.horizontal.3", title: L10n.text("footer.settings"))
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.recessedFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.subtleStroke, lineWidth: 1)
        }
    }

    private func tabButton(_ tab: UnifiedPanelTab, icon: String, title: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .imageScale(.small)
                .foregroundColor(isSelected ? palette.selectedText : palette.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 34)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? palette.selectedFill : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? palette.selectedStroke : Color.clear, lineWidth: 1)
                }
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var statusDot: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(palette.statusHaloOpacity))
                .frame(width: 13, height: 13)

            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .shadow(color: statusColor.opacity(0.36), radius: 3)
        }
        .frame(width: 16, height: 16)
    }

    private var timerPane: some View {
        VStack(spacing: 20) {
            timerDial

            actionGrid

            metricsStrip

            footerActions
        }
    }

    private var timerDial: some View {
        ZStack {
            Circle()
                .stroke(palette.timerTrack, lineWidth: 12)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: max(0.001, state.progress))
                .stroke(
                    AngularGradient(
                        colors: [palette.accent, palette.accentWarm, palette.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .shadow(color: palette.accent.opacity(0.18), radius: 14, y: 8)

            VStack(spacing: 8) {
                Text(state.formattedTime)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(palette.title)

                Text(progressCaption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(.top, 6)
    }

    private var actionGrid: some View {
        HStack(spacing: 10) {
            primaryActionButton(
                icon: state.timerPhase == .paused ? "play.fill" : "pause.fill",
                title: state.timerPhase == .paused ? L10n.text("controls.resume") : L10n.text("controls.pause"),
                action: onPauseToggle
            )

            iconActionButton(icon: "forward.end.fill", title: L10n.text("controls.skip"), action: onSkip)
            iconActionButton(icon: "arrow.counterclockwise", title: L10n.text("controls.reset"), action: onReset)
        }
        .frame(height: 46)
    }

    private func primaryActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.primaryButtonText)
                .frame(maxWidth: .infinity, minHeight: 46)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(palette.primaryButtonFill)
        }
    }

    private func iconActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .frame(width: 48, height: 46)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(palette.controlFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(palette.subtleStroke, lineWidth: 1)
        }
    }

    private var metricsStrip: some View {
        HStack(spacing: 8) {
            metricCell(value: "\(state.restCount)", label: L10n.text("stats.rest"), accent: palette.accent)
            metricCell(value: focusHoursText, label: L10n.text("stats.focus"), accent: palette.accentWarm)
            metricCell(value: "\(state.interruptCount)", label: L10n.text("stats.interrupt"), accent: palette.warning)
        }
    }

    private func metricCell(value: String, label: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .monospacedDigit()
                .lineLimit(1)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.cardFill)
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accent.opacity(0.22), lineWidth: 1)
        }
    }

    private var footerActions: some View {
        HStack(spacing: 6) {
            smallFooterButton(icon: "bell.badge.waveform", title: L10n.text("footer.test"), action: onTestReminder)
            smallFooterButton(
                icon: "arrow.triangle.2.circlepath",
                title: L10n.text("footer.updates"),
                showsBadge: hasAvailableUpdate,
                action: onCheckForUpdates
            )
            smallFooterButton(icon: "rectangle.portrait.and.arrow.right", title: L10n.text("footer.quit"), action: onQuit)
        }
        .padding(.top, 2)
    }

    private func smallFooterButton(
        icon: String,
        title: String,
        showsBadge: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 36)

                if showsBadge {
                    updateBadge
                        .offset(x: -18, y: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: showsBadge)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.recessedFill)
        }
    }

    private var updateBadge: some View {
        Circle()
            .fill(palette.warning)
            .frame(width: 8, height: 8)
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.72 : 0.95), lineWidth: 1.5)
            }
            .shadow(color: palette.warning.opacity(0.34), radius: 4, y: 1)
            .accessibilityLabel(localized(chinese: "有新版本", english: "Update available"))
    }

    private var settingsPane: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                settingsGroup("timer", title: localized(chinese: "节奏", english: "Rhythm")) {
                    sliderRow(
                        title: L10n.text("settings.reminder_interval.title"),
                        subtitle: L10n.text("settings.reminder_interval.subtitle"),
                        value: L10n.fmt("settings.fmt.minutes", Int(settings.reminderInterval / 60)),
                        binding: Binding(get: { settings.reminderInterval }, set: { settings.reminderInterval = $0 }),
                        range: (15 * 60)...(120 * 60),
                        step: 5 * 60
                    )

                    sliderRow(
                        title: L10n.text("settings.fullscreen_delay.title"),
                        subtitle: L10n.text("settings.fullscreen_delay.subtitle"),
                        value: L10n.fmt("settings.fmt.minutes", Int(settings.l3Delay / 60)),
                        binding: Binding(get: { settings.l3Delay }, set: { settings.l3Delay = $0 }),
                        range: 60...600,
                        step: 30
                    )
                }

                settingsGroup("cursorarrow.motionlines", title: localized(chinese: "感知", english: "Presence")) {
                    sliderRow(
                        title: L10n.text("settings.idle.title"),
                        subtitle: L10n.text("settings.idle.subtitle"),
                        value: L10n.fmt("settings.fmt.minutes", Int(settings.idleThreshold / 60)),
                        binding: Binding(get: { settings.idleThreshold }, set: { settings.idleThreshold = $0 }),
                        range: 60...600,
                        step: 60
                    )

                    sliderRow(
                        title: L10n.text("settings.mouse.title"),
                        subtitle: L10n.text("settings.mouse.subtitle"),
                        value: L10n.fmt("settings.fmt.pixels", Int(settings.mouseMovementThreshold)),
                        binding: Binding(get: { settings.mouseMovementThreshold }, set: { settings.mouseMovementThreshold = $0 }),
                        range: 5...50,
                        step: 5
                    )
                }

                settingsGroup("switch.2", title: localized(chinese: "偏好", english: "Preferences")) {
                    toggleRow(
                        title: L10n.text("settings.sound.title"),
                        subtitle: L10n.text("settings.sound.subtitle"),
                        isOn: Binding(get: { settings.soundEnabled }, set: { settings.soundEnabled = $0 })
                    )

                    divider

                    toggleRow(
                        title: L10n.text("settings.launch_at_login.title"),
                        subtitle: L10n.text("settings.launch_at_login.subtitle"),
                        isOn: Binding(get: { settings.launchAtLogin }, set: { settings.launchAtLogin = $0 })
                    )
                }

                settingsGroup("swatchpalette", title: localized(chinese: "主题", english: "Theme")) {
                    themePicker
                }

                settingsGroup("figure.walk", title: localized(chinese: "提醒角色", english: "Reminder Character")) {
                    reminderFigureStylePicker
                }

                settingsGroup("globe", title: localized(chinese: "语言", english: "Language")) {
                    languagePicker
                }
            }
            .padding(.bottom, 4)
        }
        .frame(height: 440)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func settingsGroup<Content: View>(
        _ icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .imageScale(.small)

            content()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.cardFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.subtleStroke, lineWidth: 1)
        }
    }

    private func sliderRow(
        title: String,
        subtitle: String,
        value: String,
        binding: Binding<TimeInterval>,
        range: ClosedRange<TimeInterval>,
        step: TimeInterval
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(palette.accent)
            }

            ThemeSlider(
                value: binding,
                range: range,
                step: step,
                palette: palette
            )
            .frame(height: 26)
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(palette.accent)
        }
    }

    private var themePicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            ForEach(UnifiedPanelTheme.allCases) { theme in
                themeChoice(theme)
            }
        }
    }

    private func themeChoice(_ theme: UnifiedPanelTheme) -> some View {
        let isSelected = settings.unifiedPanelTheme == theme
        let preview = UnifiedPanelThemePreview(theme: theme)

        return Button {
            settings.unifiedPanelTheme = theme
        } label: {
            HStack(spacing: 9) {
                HStack(spacing: 0) {
                    preview.background
                    preview.accent
                    preview.warm
                }
                .frame(width: 34, height: 18)
                .clipShape(Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(palette.subtleStroke, lineWidth: 1)
                }

                Text(theme.caption(language: settings.uiLanguage))
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(isSelected ? palette.selectedText : palette.secondaryText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 36)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? palette.selectedFill : palette.recessedFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? palette.accent.opacity(0.24) : palette.subtleStroke, lineWidth: 1)
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var reminderFigureStylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(RestReminderFigureStyle.allCases) { style in
                    figureStyleChoice(style)
                }

                ForEach(customCharacters) { character in
                    customFigureChoice(character)
                }

                addCustomFigureButton
            }
        }
    }

    private func figureStyleChoice(_ style: RestReminderFigureStyle) -> some View {
        let isSelected = settings.reminderCharacterSelection == .builtIn(style)

        return Button {
            settings.reminderCharacterSelection = .builtIn(style)
            settings.restReminderFigureStyle = style
        } label: {
            HStack(spacing: 9) {
                figurePreview(style, isSelected: isSelected)

                Text(style.caption(language: settings.uiLanguage))
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundStyle(isSelected ? palette.selectedText : palette.secondaryText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? palette.selectedFill : palette.recessedFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? palette.accent.opacity(0.24) : palette.subtleStroke, lineWidth: 1)
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func customFigureChoice(_ character: CustomReminderCharacter) -> some View {
        let isSelected = settings.reminderCharacterSelection == .custom(character.id)

        return Button {
            settings.reminderCharacterSelection = .custom(character.id)
        } label: {
            HStack(spacing: 8) {
                customFigurePreview(character)

                Text(character.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .foregroundStyle(isSelected ? palette.selectedText : palette.secondaryText)

                Spacer(minLength: 0)

                Menu {
                    Button {
                        editingCharacter = character
                    } label: {
                        Label(localized(chinese: "编辑", english: "Edit"), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        deleteCustomCharacter(character)
                    } label: {
                        Label(localized(chinese: "删除", english: "Delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? palette.accent : palette.secondaryText)
                        .frame(width: 22, height: 28)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.leading, 8)
            .padding(.trailing, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? palette.selectedFill : palette.recessedFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? palette.accent.opacity(0.24) : palette.subtleStroke, lineWidth: 1)
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var addCustomFigureButton: some View {
        Button {
            isShowingCharacterImporter = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 34, height: 34)

                Text(localized(chinese: "添加角色", english: "Add Character"))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(palette.secondaryText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(palette.recessedFill.opacity(0.74))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(palette.subtleStroke, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    @ViewBuilder
    private func figurePreview(_ style: RestReminderFigureStyle, isSelected: Bool) -> some View {
        if style == .line {
            Image(systemName: style.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? palette.accent : palette.secondaryText)
                .frame(width: 34, height: 34)
        } else {
            Image(style.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(2)
        }
    }

    @ViewBuilder
    private func customFigurePreview(_ character: CustomReminderCharacter) -> some View {
        if let image = NSImage(contentsOf: customCharacterStore.previewURL(for: character.id)) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(palette.subtleStroke, lineWidth: 1)
                }
        } else {
            Image(systemName: "photo")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(palette.secondaryText)
                .frame(width: 30, height: 30)
                .background {
                    Circle()
                        .fill(palette.controlFill)
                }
        }
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("settings.language.title"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            HStack(spacing: 6) {
                ForEach(UIAppLanguage.allCases) { lang in
                    choicePill(
                        title: lang.pickerCaption,
                        isSelected: settings.uiLanguage == lang
                    ) {
                        settings.uiLanguage = lang
                    }
                }
            }
        }
    }

    private func choicePill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .foregroundStyle(isSelected ? palette.selectedText : palette.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? palette.selectedFill : palette.recessedFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? palette.accent.opacity(0.22) : palette.subtleStroke, lineWidth: 1)
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.subtleStroke)
            .frame(height: 1)
    }

    private var statusCaption: String {
        if selectedTab == .timer {
            return warmStatusCaption
        }
        return localized(chinese: "专注节奏，一眼掌握", english: "Focus rhythm at a glance")
    }

    private var warmStatusCaption: String {
        switch (state.timerPhase, state.reminderLevel) {
        case (.paused, _):
            return localized(chinese: "暂停一下，也是在照顾自己", english: "Paused, with room to breathe")
        case (.idle, _):
            return localized(chinese: "你离开座位了，稍后再继续", english: "Away for now, resume when you return")
        case (_, .none):
            return localized(chinese: "保持节奏，记得给身体留点空隙", english: "Keep the rhythm, leave space to stretch")
        case (_, .l1), (_, .l2):
            return localized(chinese: "可以起身舒展一下了", english: "A gentle stretch would be good now")
        case (_, .l3):
            return localized(chinese: "先照顾身体，再继续专注", english: "Take care of your body before continuing")
        }
    }

    private var progressCaption: String {
        let percent = Int((state.progress * 100).rounded())
        return localized(chinese: "已完成 \(percent)%", english: "\(percent)% done")
    }

    private var focusHoursText: String {
        let hours = state.focusSeconds / 3600
        return String(format: "%.1f", hours)
    }

    private func localized(chinese: String, english: String) -> String {
        settings.uiLanguage == .english ? english : chinese
    }

    private var characterErrorTitle: String {
        localized(chinese: "无法更新提醒角色", english: "Could not update reminder character")
    }

    private var characterErrorBinding: Binding<Bool> {
        Binding(
            get: { characterErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    characterErrorMessage = nil
                }
            }
        )
    }

    private func reloadCustomCharacters() {
        do {
            customCharacters = try customCharacterStore.listCharacters()
        } catch {
            characterErrorMessage = error.localizedDescription
        }
    }

    private func deleteCustomCharacter(_ character: CustomReminderCharacter) {
        do {
            try customCharacterStore.deleteCharacter(id: character.id)
            settings.reminderCharacterSelection = CustomCharacterStore.selectionAfterDeleting(
                id: character.id,
                current: settings.reminderCharacterSelection
            )
            reloadCustomCharacters()
        } catch {
            characterErrorMessage = error.localizedDescription
        }
    }

    private func handleCharacterEditorResult(_ result: Result<CustomReminderCharacter, Error>) {
        switch result {
        case .success(let character):
            settings.reminderCharacterSelection = .custom(character.id)
            reloadCustomCharacters()
        case .failure(let error):
            characterErrorMessage = error.localizedDescription
        }
    }

    private var statusColor: Color {
        switch (state.timerPhase, state.reminderLevel) {
        case (.paused, _), (.idle, _):
            return palette.mutedStatus
        case (_, .none):
            return palette.accent
        case (_, .l1):
            return palette.accentWarm
        case (_, .l2):
            return palette.warning
        case (_, .l3):
            return palette.danger
        }
    }
}

private enum UnifiedPanelTab {
    case timer
    case settings
}

private struct UnifiedPanelThemePreview {
    let theme: UnifiedPanelTheme

    var background: Color {
        switch theme {
        case .paper:
            Color(red: 0.965, green: 0.955, blue: 0.928)
        case .sage:
            Color(red: 0.9, green: 0.94, blue: 0.89)
        case .dusk:
            Color(red: 0.89, green: 0.88, blue: 0.94)
        case .mist:
            Color(red: 0.88, green: 0.93, blue: 0.95)
        case .clay:
            Color(red: 0.95, green: 0.89, blue: 0.84)
        case .dawn:
            Color(red: 0.98, green: 0.93, blue: 0.86)
        case .frost:
            Color(red: 0.91, green: 0.93, blue: 0.94)
        case .peach:
            Color(red: 0.99, green: 0.91, blue: 0.88)
        case .garnet:
            Color(red: 0.19, green: 0.085, blue: 0.095)
        case .ink:
            Color(red: 0.12, green: 0.13, blue: 0.13)
        case .pine:
            Color(red: 0.075, green: 0.13, blue: 0.105)
        case .midnight:
            Color(red: 0.08, green: 0.09, blue: 0.13)
        }
    }

    var accent: Color {
        switch theme {
        case .paper:
            Color(red: 0.47, green: 0.68, blue: 0.47)
        case .sage:
            Color(red: 0.36, green: 0.62, blue: 0.5)
        case .dusk:
            Color(red: 0.43, green: 0.48, blue: 0.72)
        case .mist:
            Color(red: 0.35, green: 0.58, blue: 0.68)
        case .clay:
            Color(red: 0.66, green: 0.42, blue: 0.33)
        case .dawn:
            Color(red: 0.78, green: 0.56, blue: 0.34)
        case .frost:
            Color(red: 0.42, green: 0.56, blue: 0.68)
        case .peach:
            Color(red: 0.86, green: 0.48, blue: 0.42)
        case .garnet:
            Color(red: 0.72, green: 0.34, blue: 0.38)
        case .ink:
            Color(red: 0.66, green: 0.78, blue: 0.7)
        case .pine:
            Color(red: 0.5, green: 0.7, blue: 0.56)
        case .midnight:
            Color(red: 0.52, green: 0.62, blue: 0.9)
        }
    }

    var warm: Color {
        switch theme {
        case .paper:
            Color(red: 0.9, green: 0.62, blue: 0.34)
        case .sage:
            Color(red: 0.78, green: 0.58, blue: 0.35)
        case .dusk:
            Color(red: 0.82, green: 0.55, blue: 0.48)
        case .mist:
            Color(red: 0.72, green: 0.56, blue: 0.42)
        case .clay:
            Color(red: 0.82, green: 0.58, blue: 0.36)
        case .dawn:
            Color(red: 0.88, green: 0.47, blue: 0.36)
        case .frost:
            Color(red: 0.76, green: 0.6, blue: 0.46)
        case .peach:
            Color(red: 0.94, green: 0.66, blue: 0.42)
        case .garnet:
            Color(red: 0.86, green: 0.6, blue: 0.42)
        case .ink:
            Color(red: 0.84, green: 0.68, blue: 0.46)
        case .pine:
            Color(red: 0.82, green: 0.68, blue: 0.44)
        case .midnight:
            Color(red: 0.78, green: 0.58, blue: 0.88)
        }
    }
}

private struct ThemeSlider: View {
    @Binding var value: TimeInterval
    let range: ClosedRange<TimeInterval>
    let step: TimeInterval
    let palette: UnifiedPanelPalette

    private var progress: CGFloat {
        guard range.upperBound > range.lowerBound else { return 0 }
        let raw = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(CGFloat(raw), 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let knobX = progress * width

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(palette.sliderTrackFill)
                    .frame(height: 6)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.accent.opacity(0.9), palette.accentWarm.opacity(0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, knobX), height: 6)

                Circle()
                    .fill(palette.sliderKnobFill)
                    .frame(width: 18, height: 18)
                    .shadow(color: palette.softShadow, radius: 6, y: 2)
                    .overlay {
                        Circle()
                            .strokeBorder(palette.subtleStroke, lineWidth: 1)
                    }
                    .offset(x: min(max(knobX - 9, 0), max(width - 18, 0)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(locationX: gesture.location.x, width: width)
                    }
            )
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Value"))
        .accessibilityValue(Text("\(Int(value))"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }

    private func updateValue(locationX: CGFloat, width: CGFloat) {
        let clamped = min(max(locationX / max(width, 1), 0), 1)
        let raw = range.lowerBound + TimeInterval(clamped) * (range.upperBound - range.lowerBound)
        let stepped = (raw / step).rounded() * step
        value = min(max(stepped, range.lowerBound), range.upperBound)
    }
}

private struct UnifiedPanelPalette {
    let theme: UnifiedPanelTheme
    let scheme: ColorScheme

    private var usesDarkSurface: Bool {
        theme == .garnet || theme == .ink || theme == .pine || theme == .midnight || (theme == .paper && scheme == .dark)
    }

    var backgroundGradient: [Color] {
        switch theme {
        case .paper where usesDarkSurface:
            return [
                Color(red: 0.07, green: 0.068, blue: 0.061).opacity(0.96),
                Color(red: 0.115, green: 0.105, blue: 0.085).opacity(0.94),
                Color(red: 0.055, green: 0.058, blue: 0.052).opacity(0.98)
            ]
        case .paper:
            return [
                Color(red: 0.965, green: 0.955, blue: 0.928).opacity(0.96),
                Color(red: 0.985, green: 0.978, blue: 0.958).opacity(0.96),
                Color(red: 0.928, green: 0.94, blue: 0.91).opacity(0.92)
            ]
        case .sage:
            return [
                Color(red: 0.91, green: 0.945, blue: 0.895).opacity(0.97),
                Color(red: 0.965, green: 0.965, blue: 0.925).opacity(0.96),
                Color(red: 0.86, green: 0.91, blue: 0.86).opacity(0.92)
            ]
        case .dusk:
            return [
                Color(red: 0.92, green: 0.9, blue: 0.95).opacity(0.96),
                Color(red: 0.965, green: 0.94, blue: 0.92).opacity(0.94),
                Color(red: 0.86, green: 0.875, blue: 0.925).opacity(0.93)
            ]
        case .mist:
            return [
                Color(red: 0.9, green: 0.945, blue: 0.96).opacity(0.97),
                Color(red: 0.965, green: 0.965, blue: 0.94).opacity(0.95),
                Color(red: 0.84, green: 0.9, blue: 0.93).opacity(0.92)
            ]
        case .clay:
            return [
                Color(red: 0.96, green: 0.9, blue: 0.84).opacity(0.96),
                Color(red: 0.99, green: 0.955, blue: 0.9).opacity(0.95),
                Color(red: 0.91, green: 0.82, blue: 0.76).opacity(0.92)
            ]
        case .dawn:
            return [
                Color(red: 0.99, green: 0.94, blue: 0.86).opacity(0.97),
                Color(red: 0.98, green: 0.96, blue: 0.9).opacity(0.96),
                Color(red: 0.94, green: 0.88, blue: 0.82).opacity(0.92)
            ]
        case .frost:
            return [
                Color(red: 0.92, green: 0.94, blue: 0.945).opacity(0.97),
                Color(red: 0.975, green: 0.97, blue: 0.945).opacity(0.95),
                Color(red: 0.84, green: 0.875, blue: 0.9).opacity(0.92)
            ]
        case .peach:
            return [
                Color(red: 0.995, green: 0.915, blue: 0.885).opacity(0.97),
                Color(red: 0.99, green: 0.955, blue: 0.91).opacity(0.96),
                Color(red: 0.945, green: 0.845, blue: 0.825).opacity(0.92)
            ]
        case .garnet:
            return [
                Color(red: 0.16, green: 0.065, blue: 0.082).opacity(0.98),
                Color(red: 0.22, green: 0.09, blue: 0.105).opacity(0.96),
                Color(red: 0.095, green: 0.045, blue: 0.058).opacity(0.98)
            ]
        case .ink:
            return [
                Color(red: 0.095, green: 0.105, blue: 0.105).opacity(0.98),
                Color(red: 0.125, green: 0.14, blue: 0.13).opacity(0.96),
                Color(red: 0.055, green: 0.064, blue: 0.066).opacity(0.98)
            ]
        case .pine:
            return [
                Color(red: 0.055, green: 0.115, blue: 0.095).opacity(0.98),
                Color(red: 0.085, green: 0.155, blue: 0.125).opacity(0.96),
                Color(red: 0.035, green: 0.075, blue: 0.068).opacity(0.98)
            ]
        case .midnight:
            return [
                Color(red: 0.055, green: 0.065, blue: 0.105).opacity(0.98),
                Color(red: 0.09, green: 0.095, blue: 0.16).opacity(0.96),
                Color(red: 0.04, green: 0.045, blue: 0.08).opacity(0.98)
            ]
        }
    }

    var title: Color {
        usesDarkSurface ? Color(red: 0.95, green: 0.925, blue: 0.86) : Color(red: 0.12, green: 0.112, blue: 0.095)
    }

    var primaryText: Color {
        usesDarkSurface ? Color.white.opacity(0.86) : Color(red: 0.16, green: 0.145, blue: 0.12)
    }

    var secondaryText: Color {
        usesDarkSurface ? Color.white.opacity(0.58) : Color(red: 0.28, green: 0.25, blue: 0.2).opacity(0.74)
    }

    var selectedText: Color {
        usesDarkSurface ? Color.white : Color(red: 0.09, green: 0.085, blue: 0.065)
    }

    var primaryButtonText: Color {
        Color(red: 0.08, green: 0.085, blue: 0.07)
    }

    var accent: Color {
        UnifiedPanelThemePreview(theme: theme).accent
    }

    var accentWarm: Color {
        UnifiedPanelThemePreview(theme: theme).warm
    }

    var warning: Color {
        Color(red: 0.86, green: 0.45, blue: 0.28)
    }

    var danger: Color {
        Color(red: 0.82, green: 0.24, blue: 0.23)
    }

    var mutedStatus: Color {
        usesDarkSurface ? Color.white.opacity(0.54) : Color.black.opacity(0.38)
    }

    var subtleStroke: Color {
        usesDarkSurface ? Color.white.opacity(0.12) : Color.black.opacity(0.095)
    }

    var softShadow: Color {
        usesDarkSurface ? Color.black.opacity(0.2) : Color.black.opacity(0.08)
    }

    var recessedFill: Color {
        usesDarkSurface ? Color.black.opacity(0.24) : Color.white.opacity(0.52)
    }

    var selectedFill: Color {
        accent.opacity(usesDarkSurface ? 0.18 : 0.16)
    }

    var selectedStroke: Color {
        accent.opacity(usesDarkSurface ? 0.26 : 0.22)
    }

    var statusHaloOpacity: Double {
        usesDarkSurface ? 0.16 : 0.13
    }

    var cardFill: Color {
        usesDarkSurface ? Color.white.opacity(0.07) : Color.white.opacity(0.54)
    }

    var controlFill: Color {
        usesDarkSurface ? Color.white.opacity(0.085) : Color.white.opacity(0.58)
    }

    var timerTrack: Color {
        usesDarkSurface ? Color.white.opacity(0.11) : Color.black.opacity(0.095)
    }

    var sliderTrackFill: Color {
        usesDarkSurface ? Color.white.opacity(0.11) : Color.black.opacity(0.09)
    }

    var sliderKnobFill: Color {
        usesDarkSurface ? Color(red: 0.18, green: 0.2, blue: 0.19) : Color.white.opacity(0.92)
    }

    var primaryButtonFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.81, green: 0.74, blue: 0.57),
                accent.opacity(0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
