import Foundation

enum UnifiedPanelTheme: String, CaseIterable, Identifiable {
    case paper
    case sage
    case dusk
    case mist
    case clay
    case dawn
    case frost
    case peach
    case garnet
    case ink
    case pine
    case midnight

    var id: String { rawValue }

    func caption(language: UIAppLanguage) -> String {
        let usesEnglish = language == .english
        switch self {
        case .paper:
            return usesEnglish ? "Paper" : "纸白"
        case .sage:
            return usesEnglish ? "Sage" : "鼠尾草"
        case .dusk:
            return usesEnglish ? "Dusk" : "薄暮"
        case .mist:
            return usesEnglish ? "Mist" : "雾蓝"
        case .clay:
            return usesEnglish ? "Clay" : "陶土"
        case .dawn:
            return usesEnglish ? "Dawn" : "晨光"
        case .frost:
            return usesEnglish ? "Frost" : "霜银"
        case .peach:
            return usesEnglish ? "Peach" : "桃金"
        case .garnet:
            return usesEnglish ? "Garnet" : "石榴"
        case .ink:
            return usesEnglish ? "Ink" : "墨色"
        case .pine:
            return usesEnglish ? "Pine" : "松影"
        case .midnight:
            return usesEnglish ? "Midnight" : "午夜"
        }
    }
}
