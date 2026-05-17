import SwiftUI

/// Menu bar chrome preference. Stored value may be `.system`; UI always injects a resolved `.dark`/`.light` palette via `SitWatcherAppearanceScope`.
enum SitWatcherPanelAppearance: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    /// Non-nil overrides SwiftUI / window appearance; `.system` mode leaves macOS preference intact.
    var preferredSchemeOverride: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }

    /// Segment captions stay literal-ish where needed so presets remain recognizable.
    var pickerCaption: String {
        switch self {
        case .system: L10n.text("settings.appearance.option_system")
        case .dark: L10n.text("settings.appearance.option_dark")
        case .light: L10n.text("settings.appearance.option_light")
        }
    }

    /// Collapses `.system` using the ambient ``ColorScheme``. `.dark`/`.light` ignore that parameter.
    func resolvedPalette(for colorScheme: ColorScheme) -> SitWatcherPanelAppearance {
        switch self {
        case .dark, .light:
            self
        case .system:
            colorScheme == .dark ? .dark : .light
        }
    }
}

extension SitWatcherPanelAppearance {

    /// All chrome below only distinguishes `.dark` vs `.light`. Unresolved `.system` mirrors `.light` (should never hit environment reads).
    private enum ResolvedTone {
        case dark
        case light

        init(palette: SitWatcherPanelAppearance) {
            switch palette {
            case .dark:
                self = .dark
            case .light, .system:
                self = .light
            }
        }
    }

    private var tone: ResolvedTone { ResolvedTone(palette: self) }

    var primaryLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.92)
        case .light: Color(red: 0.13, green: 0.14, blue: 0.17)
        }
    }

    var secondaryLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.48)
        case .light: Color(red: 0.13, green: 0.14, blue: 0.17).opacity(0.55)
        }
    }

    var tertiaryLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.62)
        case .light: Color(red: 0.13, green: 0.14, blue: 0.17).opacity(0.45)
        }
    }

    /// Primary title row (cards, headers).
    var headlineLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.96)
        case .light: Color(red: 0.09, green: 0.1, blue: 0.12).opacity(0.92)
        }
    }

    var segmentInactiveLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.78)
        case .light: Color(red: 0.13, green: 0.14, blue: 0.17).opacity(0.62)
        }
    }

    var segmentActiveLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.98)
        case .light: Color(red: 0.05, green: 0.06, blue: 0.07)
        }
    }

    /// Status pill idle / paused muted dot or similar.
    var statusMuted: Color {
        switch tone {
        case .dark: Color.white.opacity(0.45)
        case .light: Color.black.opacity(0.28)
        }
    }

    var switchesCardFill: Color {
        switch tone {
        case .dark: Color.white.opacity(0.1)
        case .light: Color.white.opacity(0.92)
        }
    }

    var embossedCardFill: Color {
        switch tone {
        case .dark: Color.white.opacity(0.065)
        case .light: Color.white.opacity(0.94)
        }
    }

    var hairlineMuted: Color {
        switch tone {
        case .dark: Color.white.opacity(0.1)
        case .light: Color.black.opacity(0.08)
        }
    }

    var footerBarFill: Color {
        switch tone {
        case .dark: Color.white.opacity(0.06)
        case .light: Color.black.opacity(0.035)
        }
    }

    var footerItemLabel: Color {
        switch tone {
        case .dark: Color.white.opacity(0.72)
        case .light: Color(red: 0.13, green: 0.14, blue: 0.17).opacity(0.78)
        }
    }

    var segmentSelectedBackdrop: Color {
        switch tone {
        case .dark: Color.white.opacity(0.16)
        case .light: Color.black.opacity(0.06)
        }
    }

    var timerTrack: Color {
        switch tone {
        case .dark: Color.white.opacity(0.1)
        case .light: Color.black.opacity(0.08)
        }
    }

    var timerSubtitle: Color {
        switch tone {
        case .dark: Color.white.opacity(0.45)
        case .light: Color.black.opacity(0.42)
        }
    }

    var timerDigitsGradientColors: [Color] {
        switch tone {
        case .dark:
            [.white, SitWatcherPanelChrome.mint.opacity(0.92)]
        case .light:
            [Color(red: 0.1, green: 0.11, blue: 0.13), SitWatcherPanelChrome.mint.opacity(0.92)]
        }
    }

    var statCardBackdrop: Color {
        switch tone {
        case .dark: Color.white.opacity(0.07)
        case .light: Color.white.opacity(0.98)
        }
    }

    var statStrokeTerminal: Color {
        switch tone {
        case .dark: Color.white.opacity(0.08)
        case .light: Color.black.opacity(0.08)
        }
    }

    var statLabelMuted: Color {
        switch tone {
        case .dark: Color.white.opacity(0.48)
        case .light: Color.black.opacity(0.45)
        }
    }

    func statValueGradient(accent: Color) -> LinearGradient {
        LinearGradient(
            colors: valueGradient(accent: accent),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func valueGradient(accent: Color) -> [Color] {
        switch tone {
        case .dark:
            [.white, accent.opacity(0.9)]
        case .light:
            [Color(red: 0.1, green: 0.11, blue: 0.13), accent.opacity(0.9)]
        }
    }

    var controlMutedForeground: Color {
        switch tone {
        case .dark: Color.white.opacity(0.92)
        case .light: Color(red: 0.14, green: 0.16, blue: 0.2)
        }
    }

    var floatingTitleGradient: LinearGradient {
        switch tone {
        case .dark:
            LinearGradient(
                colors: [.white, SitWatcherPanelChrome.mint.opacity(0.95)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .light:
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.11, blue: 0.13), SitWatcherPanelChrome.mint.opacity(0.92)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var floatingBody: Color {
        switch tone {
        case .dark: Color.white.opacity(0.68)
        case .light: Color.black.opacity(0.52)
        }
    }

    var floatingSnoozeForeground: Color {
        switch tone {
        case .dark: Color.white.opacity(0.82)
        case .light: Color(red: 0.14, green: 0.16, blue: 0.2).opacity(0.88)
        }
    }

    var floatingSnoozeFill: Color {
        switch tone {
        case .dark: Color.white.opacity(0.12)
        case .light: Color.white.opacity(0.85)
        }
    }

    var fullscreenTitleGradient: LinearGradient {
        switch tone {
        case .dark:
            LinearGradient(
                colors: [.white, SitWatcherPanelChrome.mint.opacity(0.95)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .light:
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.93, blue: 0.95),
                    SitWatcherPanelChrome.mint.opacity(0.93),
                    SitWatcherPanelChrome.cyan.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var fullscreenSubtitle: Color {
        switch tone {
        case .dark: Color.white.opacity(0.72)
        case .light: Color(red: 0.93, green: 0.96, blue: 0.97).opacity(0.95)
        }
    }

    /// Full-screen scrim multiplier (paired with tinted overlay).
    var fullscreenScrimOpacity: Double {
        switch tone {
        case .dark: 0.88
        case .light: 0.48
        }
    }
}

private struct SitWatcherPanelAppearanceKey: EnvironmentKey {
    static let defaultValue: SitWatcherPanelAppearance = .dark
}

extension EnvironmentValues {
    var sitWatcherPanelAppearance: SitWatcherPanelAppearance {
        get { self[SitWatcherPanelAppearanceKey.self] }
        set { self[SitWatcherPanelAppearanceKey.self] = newValue }
    }
}
