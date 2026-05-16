import Foundation

enum L10n {
    /// Prefer `LocalizedStringResource` so String Catalog lookups respect runtime `locale`.
    static func text(_ key: String.LocalizationValue) -> String {
        var resource = LocalizedStringResource(key)
        resource.locale = Settings.shared.localizationLocale
        return String(localized: resource)
    }

    static func fmt(_ key: String.LocalizationValue, _ arguments: Any...) -> String {
        let locale = Settings.shared.localizationLocale
        let tmpl = text(key)
        let args = arguments.map { $0 as! CVarArg }
        return String(format: tmpl, locale: locale, arguments: args)
    }
}
