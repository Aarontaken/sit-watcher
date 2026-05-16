import Foundation

/// Stored in defaults; persisted under `Settings.uiLanguage`.
enum UIAppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    /// Segment labels (`English` / `简体中文` stay literal so they remain recognizable regardless of chosen UI locale).
    var pickerCaption: String {
        switch self {
        case .system:
            // Deliberately use system locale for this meta-option so it stays aligned with macOS language.
            String(
                localized: String.LocalizationValue("settings.language.system"),
                bundle: Bundle.main,
                locale: Locale.autoupdatingCurrent
            )
        case .english:
            "English"
        case .simplifiedChinese:
            "简体中文"
        }
    }
}
