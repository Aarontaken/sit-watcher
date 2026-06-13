import SwiftUI

enum RestReminderFigureStyle: String, CaseIterable, Identifiable {
    case line
    case walk
    case stretch
    case sway
    case breathe
    case pixelWalk
    case pixelStretch
    case pixelJump
    case pixelHydrate

    var id: String { rawValue }

    func caption(language: UIAppLanguage) -> String {
        let usesEnglish = language == .english
        switch self {
        case .line:
            return usesEnglish ? "Line Figure" : "线条小人"
        case .walk:
            return usesEnglish ? "Lazy Stretch" : "伸个懒腰"
        case .stretch:
            return usesEnglish ? "Stretch" : "伸展放松"
        case .sway:
            return usesEnglish ? "Sway" : "轻轻摇摆"
        case .breathe:
            return usesEnglish ? "Breathe" : "安静呼吸"
        case .pixelWalk:
            return usesEnglish ? "Pixel Walk" : "像素散步"
        case .pixelStretch:
            return usesEnglish ? "Pixel Stretch" : "像素伸展"
        case .pixelJump:
            return usesEnglish ? "Pixel Hop" : "像素轻跳"
        case .pixelHydrate:
            return usesEnglish ? "Pixel Sip" : "像素喝水"
        }
    }

    var assetName: String {
        switch self {
        case .line:
            return ""
        case .walk:
            return "ReminderFigureWalk"
        case .stretch:
            return "ReminderFigureStretch"
        case .sway:
            return "ReminderFigureSway"
        case .breathe:
            return "ReminderFigureBreathe"
        case .pixelWalk:
            return "ReminderFigurePixelWalk"
        case .pixelStretch:
            return "ReminderFigurePixelStretch"
        case .pixelJump:
            return "ReminderFigurePixelJump"
        case .pixelHydrate:
            return "ReminderFigurePixelHydrate"
        }
    }

    var frameAssetNames: [String] {
        switch self {
        case .line:
            return []
        case .walk:
            return (1...4).map { "ReminderFigureWalkFrame\($0)" }
        case .stretch:
            return (1...4).map { "ReminderFigureStretchFrame\($0)" }
        case .sway:
            return (1...4).map { "ReminderFigureSwayFrame\($0)" }
        case .breathe:
            return (1...4).map { "ReminderFigureBreatheFrame\($0)" }
        case .pixelWalk:
            return (1...4).map { "ReminderFigurePixelWalkFrame\($0)" }
        case .pixelStretch:
            return (1...4).map { "ReminderFigurePixelStretchFrame\($0)" }
        case .pixelJump:
            return (1...4).map { "ReminderFigurePixelJumpFrame\($0)" }
        case .pixelHydrate:
            return (1...4).map { "ReminderFigurePixelHydrateFrame\($0)" }
        }
    }

    var frameInterval: TimeInterval {
        switch self {
        case .line:
            return 0.52
        case .walk:
            return 0.42
        case .stretch:
            return 0.34
        case .sway:
            return 0.25
        case .breathe:
            return 0.62
        case .pixelWalk:
            return 0.18
        case .pixelStretch:
            return 0.22
        case .pixelJump:
            return 0.16
        case .pixelHydrate:
            return 0.24
        }
    }

    var iconName: String {
        switch self {
        case .line:
            return "figure.walk.motion"
        case .walk:
            return "figure.flexibility"
        case .stretch:
            return "figure.flexibility"
        case .sway:
            return "figure.dance"
        case .breathe:
            return "figure.mind.and.body"
        case .pixelWalk:
            return "figure.walk.motion"
        case .pixelStretch:
            return "figure.flexibility"
        case .pixelJump:
            return "figure.jumprope"
        case .pixelHydrate:
            return "waterbottle"
        }
    }
}

enum RestReminderPanelMetrics {
    static let width: CGFloat = 336
    static let height: CGFloat = 316
}

struct RestReminderFloatingView: View {
    let sittingMinutes: Int
    let canSnooze: Bool
    var onConfirm: () -> Void
    var onSnooze: () -> Void

    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    private var palette: RestReminderPalette {
        RestReminderPalette(theme: settings.unifiedPanelTheme, scheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 12) {
            ReminderCharacterFigureView(
                palette: palette,
                size: 126,
                selection: settings.reminderCharacterSelection,
                isActive: !reduceMotion
            )

            VStack(spacing: 6) {
                Text(localized(chinese: "活动一下吧", english: "Time for a tiny reset"))
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.title)
                    .lineLimit(1)

                Text(localized(
                    chinese: "已经坐了 \(sittingMinutes) 分钟，伸展一下，喝口水也好。",
                    english: "\(sittingMinutes) minutes seated. Stretch, sip water, or move a little."
                ))
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }

            HStack(spacing: 10) {
                primaryButton(
                    title: localized(chinese: "我去活动", english: "I’ll move"),
                    icon: "figure.walk",
                    action: onConfirm
                )

                if canSnooze {
                    quietButton(
                        title: localized(chinese: "稍后 5 分钟", english: "5 min later"),
                        icon: "clock",
                        action: onSnooze
                    )
                }
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .frame(width: RestReminderPanelMetrics.width, height: RestReminderPanelMetrics.height, alignment: .center)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: palette.panelGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .scaleEffect(didAppear ? 1 : 0.985)
        .opacity(didAppear ? 1 : 0)
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86), value: didAppear)
        .onAppear {
            didAppear = true
        }
    }

    private func primaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.primaryButtonText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.accent, palette.accentWarm],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func quietButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(palette.controlFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(palette.stroke, lineWidth: 1)
        }
    }

    private func localized(chinese: String, english: String) -> String {
        settings.uiLanguage == .english ? english : chinese
    }
}

struct RestReminderFullScreenView: View {
    let sittingMinutes: Int
    var onDismiss: () -> Void

    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    private var palette: RestReminderPalette {
        RestReminderPalette(theme: settings.unifiedPanelTheme, scheme: colorScheme)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: palette.fullscreenGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: max(42, proxy.safeAreaInsets.top + 28))

                    VStack(spacing: 24) {
                        ReminderCharacterFigureView(
                            palette: palette,
                            size: 206,
                            selection: settings.reminderCharacterSelection,
                            isActive: !reduceMotion
                        )

                        VStack(spacing: 12) {
                            Text(localized(chinese: "先活动一下", english: "Take a real reset"))
                                .font(.system(size: min(proxy.size.width * 0.052, 56), weight: .semibold, design: .serif))
                                .foregroundStyle(palette.fullscreenTitle)
                                .lineLimit(1)
                                .minimumScaleFactor(0.68)

                            Text(localized(
                                chinese: "你已经坐了 \(sittingMinutes) 分钟，站起来伸展、喝水，给身体换个节奏。",
                                english: "\(sittingMinutes) minutes seated. Stand, stretch, hydrate, and change the rhythm."
                            ))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(palette.fullscreenBody)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 560)
                        }

                        Button(action: onDismiss) {
                            Label(localized(chinese: "我已经起身", english: "I’m up now"), systemImage: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.primaryButtonText)
                                .frame(minWidth: 230, minHeight: 50)
                                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [palette.accent, palette.accentWarm],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                    .offset(y: didAppear ? 0 : 8)
                    .opacity(didAppear ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.38), value: didAppear)

                    Spacer(minLength: max(42, proxy.safeAreaInsets.bottom + 28))
                }
            }
        }
        .onAppear {
            didAppear = true
        }
    }

    private func localized(chinese: String, english: String) -> String {
        settings.uiLanguage == .english ? english : chinese
    }
}

struct BuiltInReminderCharacterFigure: View {
    let palette: RestReminderPalette
    let size: CGFloat
    let style: RestReminderFigureStyle
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationPhase = false
    @State private var frameIndex = 0
    @State private var frameTaskID = UUID()

    private var scale: CGFloat {
        size / 100
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule(style: .continuous)
                .fill(palette.figureGround)
                .frame(width: 62 * scale, height: 5 * scale)
                .offset(y: 2 * scale)

            if style == .line {
                RestReminderLineFigure(
                    palette: palette,
                    size: size,
                    isActive: isAnimating
                )
            } else {
                Image(currentAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize.width, height: imageSize.height)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .onAppear(perform: restartAnimation)
        .onChange(of: style) { _, _ in
            restartAnimation()
        }
        .onChange(of: isActive) { _, _ in
            restartAnimation()
        }
        .onChange(of: reduceMotion) { _, _ in
            restartAnimation()
        }
        .task(id: frameTaskID) {
            await runFrameAnimation()
        }
    }

    private var isAnimating: Bool {
        isActive && !reduceMotion && animationPhase
    }

    private var currentAssetName: String {
        if reduceMotion || !isActive {
            return style.assetName
        }
        let frames = style.frameAssetNames
        guard frames.isEmpty == false else { return style.assetName }
        return frames[min(frameIndex, frames.count - 1)]
    }

    private var imageSize: CGSize {
        switch style {
        case .line:
            CGSize(width: 84 * scale, height: 84 * scale)
        case .walk:
            CGSize(width: 86 * scale, height: 86 * scale)
        case .stretch:
            CGSize(width: 82 * scale, height: 82 * scale)
        case .sway:
            CGSize(width: 90 * scale, height: 90 * scale)
        case .breathe:
            CGSize(width: 92 * scale, height: 92 * scale)
        case .pixelWalk, .pixelStretch, .pixelJump, .pixelHydrate:
            CGSize(width: 86 * scale, height: 86 * scale)
        }
    }

    private var animationOffset: CGSize {
        guard isAnimating else { return .zero }
        switch style {
        case .line:
            return CGSize(width: 4 * scale, height: -1.5 * scale)
        case .walk:
            return CGSize(width: 3 * scale, height: -2 * scale)
        case .stretch:
            return CGSize(width: 0, height: -4 * scale)
        case .sway:
            return CGSize(width: -3 * scale, height: -1 * scale)
        case .breathe:
            return CGSize(width: 0, height: -2 * scale)
        case .pixelWalk:
            return CGSize(width: 2 * scale, height: -1 * scale)
        case .pixelStretch:
            return CGSize(width: 0, height: -3 * scale)
        case .pixelJump:
            return CGSize(width: 0, height: -5 * scale)
        case .pixelHydrate:
            return CGSize(width: 1 * scale, height: -1 * scale)
        }
    }

    private var animationRotation: Double {
        guard isAnimating else { return 0 }
        switch style {
        case .line:
            return 0
        case .walk:
            return 1.5
        case .stretch:
            return 0
        case .sway:
            return -3
        case .breathe:
            return 0
        case .pixelWalk:
            return 0
        case .pixelStretch:
            return 0
        case .pixelJump:
            return 0
        case .pixelHydrate:
            return -1
        }
    }

    private var animationScale: CGFloat {
        guard isAnimating else { return 1 }
        switch style {
        case .line:
            return 1
        case .walk:
            return 1.02
        case .stretch:
            return 1.045
        case .sway:
            return 1.015
        case .breathe:
            return 1.055
        case .pixelWalk:
            return 1
        case .pixelStretch:
            return 1.02
        case .pixelJump:
            return 1.025
        case .pixelHydrate:
            return 1.01
        }
    }

    private func restartAnimation() {
        animationPhase = false
        frameIndex = 0
        frameTaskID = UUID()
        guard isActive, reduceMotion == false else { return }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                animationPhase = true
            }
        }
    }

    private var animationDuration: TimeInterval {
        switch style {
        case .line, .walk:
            return 0.52
        case .stretch:
            return 0.72
        case .sway:
            return 0.58
        case .breathe:
            return 1.05
        case .pixelWalk:
            return 0.36
        case .pixelStretch:
            return 0.48
        case .pixelJump:
            return 0.34
        case .pixelHydrate:
            return 0.58
        }
    }

    private func runFrameAnimation() async {
        guard isActive, reduceMotion == false else { return }
        let frames = style.frameAssetNames
        guard frames.count > 1 else { return }

        while Task.isCancelled == false {
            let delay = UInt64(style.frameInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                frameIndex = (frameIndex + 1) % frames.count
            }
        }
    }
}

private struct RestReminderLineFigure: View {
    let palette: RestReminderPalette
    let size: CGFloat
    let isActive: Bool

    private var scale: CGFloat {
        size / 100
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(headFill)
                .frame(width: 16 * scale, height: 16 * scale)
                .offset(x: 6 * scale, y: -39 * scale)

            Capsule(style: .continuous)
                .fill(bodyFill)
                .frame(width: 18 * scale, height: 36 * scale)
                .rotationEffect(.degrees(isActive ? -8 : 8))
                .offset(x: 2 * scale, y: -14 * scale)

            Capsule(style: .continuous)
                .fill(limbFill)
                .frame(width: 8 * scale, height: 38 * scale)
                .rotationEffect(.degrees(isActive ? 34 : -30))
                .offset(x: isActive ? -13 * scale : 11 * scale, y: 9 * scale)

            Capsule(style: .continuous)
                .fill(limbFill)
                .frame(width: 8 * scale, height: 38 * scale)
                .rotationEffect(.degrees(isActive ? -30 : 34))
                .offset(x: isActive ? 12 * scale : -13 * scale, y: 9 * scale)

            Capsule(style: .continuous)
                .fill(limbFill)
                .frame(width: 7 * scale, height: 34 * scale)
                .rotationEffect(.degrees(isActive ? 55 : -42))
                .offset(x: isActive ? -16 * scale : 17 * scale, y: -20 * scale)

            Capsule(style: .continuous)
                .fill(limbFill)
                .frame(width: 7 * scale, height: 34 * scale)
                .rotationEffect(.degrees(isActive ? -42 : 55))
                .offset(x: isActive ? 18 * scale : -16 * scale, y: -20 * scale)
        }
        .offset(x: isActive ? 5 * scale : -5 * scale, y: isActive ? -1.5 * scale : 0)
        .accessibilityHidden(true)
    }

    private var headFill: AnyShapeStyle {
        AnyShapeStyle(palette.figureHead)
    }

    private var bodyFill: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [palette.accent, palette.accentWarm],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var limbFill: AnyShapeStyle {
        AnyShapeStyle(palette.figureLine)
    }
}

struct RestReminderPalette {
    let theme: UnifiedPanelTheme
    let scheme: ColorScheme

    private var isDark: Bool {
        theme == .garnet || theme == .ink || theme == .pine || theme == .midnight || (theme == .paper && scheme == .dark)
    }

    var accent: Color {
        switch theme {
        case .paper: Color(red: 0.42, green: 0.62, blue: 0.46)
        case .sage: Color(red: 0.34, green: 0.62, blue: 0.5)
        case .dusk: Color(red: 0.52, green: 0.54, blue: 0.78)
        case .mist, .frost: Color(red: 0.36, green: 0.58, blue: 0.68)
        case .clay, .dawn, .peach: Color(red: 0.78, green: 0.48, blue: 0.38)
        case .garnet: Color(red: 0.84, green: 0.46, blue: 0.48)
        case .ink: Color(red: 0.58, green: 0.76, blue: 0.66)
        case .pine: Color(red: 0.54, green: 0.75, blue: 0.56)
        case .midnight: Color(red: 0.55, green: 0.66, blue: 0.95)
        }
    }

    var accentWarm: Color {
        switch theme {
        case .garnet: Color(red: 0.9, green: 0.64, blue: 0.42)
        case .ink, .pine, .midnight: Color(red: 0.84, green: 0.68, blue: 0.45)
        default: Color(red: 0.9, green: 0.62, blue: 0.42)
        }
    }

    var panelGradient: [Color] {
        if isDark {
            return [
                Color(red: 0.105, green: 0.11, blue: 0.102).opacity(0.98),
                Color(red: 0.13, green: 0.15, blue: 0.132).opacity(0.95),
                Color(red: 0.07, green: 0.074, blue: 0.07).opacity(0.99)
            ]
        }
        return [
            Color(red: 0.985, green: 0.965, blue: 0.92).opacity(0.96),
            Color(red: 0.95, green: 0.965, blue: 0.93).opacity(0.95),
            Color(red: 0.93, green: 0.91, blue: 0.86).opacity(0.92)
        ]
    }

    var fullscreenGradient: [Color] {
        if isDark {
            return [
                Color(red: 0.035, green: 0.04, blue: 0.04),
                Color(red: 0.075, green: 0.095, blue: 0.082),
                Color(red: 0.02, green: 0.025, blue: 0.028)
            ]
        }
        return [
            Color(red: 0.94, green: 0.925, blue: 0.875),
            Color(red: 0.91, green: 0.945, blue: 0.905),
            Color(red: 0.865, green: 0.885, blue: 0.86)
        ]
    }

    var title: Color {
        isDark ? Color(red: 0.96, green: 0.93, blue: 0.84) : Color(red: 0.16, green: 0.13, blue: 0.095)
    }

    var primaryText: Color {
        isDark ? Color.white.opacity(0.84) : Color(red: 0.17, green: 0.145, blue: 0.108)
    }

    var secondaryText: Color {
        isDark ? Color.white.opacity(0.56) : Color(red: 0.34, green: 0.29, blue: 0.22).opacity(0.72)
    }

    var primaryButtonText: Color {
        Color(red: 0.055, green: 0.06, blue: 0.052)
    }

    var stroke: Color {
        isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.075)
    }

    var shadow: Color {
        isDark ? Color.black.opacity(0.22) : Color.black.opacity(0.12)
    }

    var markFill: Color {
        isDark ? Color.white.opacity(0.07) : Color.white.opacity(0.52)
    }

    var cardFill: Color {
        isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.44)
    }

    var controlFill: Color {
        isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.56)
    }

    var restStepFill: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    var fullscreenTitle: Color {
        isDark ? Color(red: 0.98, green: 0.955, blue: 0.88) : Color(red: 0.14, green: 0.12, blue: 0.09)
    }

    var fullscreenBody: Color {
        isDark ? Color.white.opacity(0.66) : Color(red: 0.24, green: 0.205, blue: 0.16).opacity(0.78)
    }

    var fullscreenFootnote: Color {
        isDark ? Color.white.opacity(0.42) : Color.black.opacity(0.42)
    }

    var fullscreenMarkFill: Color {
        isDark ? Color.white.opacity(0.065) : Color.white.opacity(0.36)
    }

    var figureHead: Color {
        isDark ? Color(red: 0.98, green: 0.9, blue: 0.76) : Color(red: 0.28, green: 0.22, blue: 0.16)
    }

    var figureLine: Color {
        isDark ? Color.white.opacity(0.78) : Color(red: 0.22, green: 0.18, blue: 0.13).opacity(0.82)
    }

    var figureSilhouette: Color {
        isDark ? Color(red: 0.95, green: 0.92, blue: 0.82) : Color(red: 0.12, green: 0.105, blue: 0.085)
    }

    var figureGround: Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }
}
