import Foundation
import Combine
import ServiceManagement

final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults: UserDefaults

    var reminderInterval: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(reminderInterval, forKey: "reminderInterval") }
    }

    var l2Delay: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(l2Delay, forKey: "l2Delay") }
    }

    var l3Delay: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(l3Delay, forKey: "l3Delay") }
    }

    var idleThreshold: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(idleThreshold, forKey: "idleThreshold") }
    }

    var mouseMovementThreshold: Double {
        willSet { objectWillChange.send() }
        didSet { defaults.set(mouseMovementThreshold, forKey: "mouseMovementThreshold") }
    }

    var soundEnabled: Bool {
        willSet { objectWillChange.send() }
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    var launchAtLogin: Bool {
        willSet { objectWillChange.send() }
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var uiLanguage: UIAppLanguage {
        didSet {
            defaults.set(uiLanguage.rawValue, forKey: "uiLanguage")
        }
    }

    /// Menu bar panel & settings styling. Default follows macOS appearance.
    @Published var uiPanelAppearance: SitWatcherPanelAppearance {
        didSet {
            defaults.set(uiPanelAppearance.rawValue, forKey: "uiPanelAppearance")
        }
    }

    @Published var unifiedPanelTheme: UnifiedPanelTheme {
        didSet {
            defaults.set(unifiedPanelTheme.rawValue, forKey: "unifiedPanelTheme")
        }
    }

    @Published var reminderCharacterSelection: ReminderCharacterSelection = .builtIn(.line) {
        didSet {
            defaults.set(reminderCharacterSelection.storedString, forKey: "reminderCharacterSelection")
            if case .builtIn(let style) = reminderCharacterSelection, restReminderFigureStyle != style {
                restReminderFigureStyle = style
            }
        }
    }

    @Published var restReminderFigureStyle: RestReminderFigureStyle {
        didSet {
            defaults.set(restReminderFigureStyle.rawValue, forKey: "restReminderFigureStyle")
            if reminderCharacterSelection != .builtIn(restReminderFigureStyle) {
                reminderCharacterSelection = .builtIn(restReminderFigureStyle)
            }
        }
    }

    /// Used for SwiftUI `\\.locale` + `String(localized:bundle:locale:)` — always concrete (never `nil`).
    var localizationLocale: Locale {
        switch uiLanguage {
        case .system:
            Locale.autoupdatingCurrent
        case .english:
            Locale(identifier: "en")
        case .simplifiedChinese:
            Locale(identifier: "zh-Hans")
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            "reminderInterval": 30.0 * 60,
            "l2Delay": 2.0 * 60,
            "l3Delay": 2.0 * 60,
            "idleThreshold": 5.0 * 60,
            "mouseMovementThreshold": 10.0,
            "soundEnabled": true,
            "launchAtLogin": false,
            "uiLanguage": UIAppLanguage.system.rawValue,
            "uiPanelAppearance": SitWatcherPanelAppearance.system.rawValue,
            "unifiedPanelTheme": UnifiedPanelTheme.paper.rawValue,
            "restReminderFigureStyle": RestReminderFigureStyle.line.rawValue,
        ])

        let interval = defaults.double(forKey: "reminderInterval")
        self.reminderInterval = interval > 0 ? interval : 30 * 60

        let l2 = defaults.double(forKey: "l2Delay")
        self.l2Delay = l2 > 0 ? l2 : 2 * 60

        let l3 = defaults.double(forKey: "l3Delay")
        self.l3Delay = l3 > 0 ? l3 : 2 * 60

        let idle = defaults.double(forKey: "idleThreshold")
        self.idleThreshold = idle > 0 ? idle : 5 * 60

        let mouse = defaults.double(forKey: "mouseMovementThreshold")
        self.mouseMovementThreshold = mouse > 0 ? mouse : 10.0

        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        let langRaw = defaults.string(forKey: "uiLanguage") ?? UIAppLanguage.system.rawValue
        self.uiLanguage = UIAppLanguage(rawValue: langRaw) ?? .system

        let panelRaw = defaults.string(forKey: "uiPanelAppearance") ?? SitWatcherPanelAppearance.system.rawValue
        self.uiPanelAppearance = SitWatcherPanelAppearance(rawValue: panelRaw) ?? .system

        let themeRaw = defaults.string(forKey: "unifiedPanelTheme") ?? UnifiedPanelTheme.paper.rawValue
        self.unifiedPanelTheme = UnifiedPanelTheme(rawValue: themeRaw) ?? .paper

        let figureStyleRaw = defaults.string(forKey: "restReminderFigureStyle") ?? RestReminderFigureStyle.line.rawValue
        self.restReminderFigureStyle = RestReminderFigureStyle(rawValue: figureStyleRaw) ?? .line

        let hasStoredSelection = defaults.object(forKey: "reminderCharacterSelection") != nil
        let storedSelection = hasStoredSelection ? defaults.string(forKey: "reminderCharacterSelection") : nil
        if hasStoredSelection {
            self.reminderCharacterSelection = ReminderCharacterSelection.fromStoredString(storedSelection)
        } else {
            self.reminderCharacterSelection = .builtIn(self.restReminderFigureStyle)
        }

        defaults.set(reminderInterval, forKey: "reminderInterval")
        defaults.set(l2Delay, forKey: "l2Delay")
        defaults.set(l3Delay, forKey: "l3Delay")
        defaults.set(idleThreshold, forKey: "idleThreshold")
        defaults.set(mouseMovementThreshold, forKey: "mouseMovementThreshold")
        defaults.set(soundEnabled, forKey: "soundEnabled")
        defaults.set(uiLanguage.rawValue, forKey: "uiLanguage")
        defaults.set(uiPanelAppearance.rawValue, forKey: "uiPanelAppearance")
        defaults.set(unifiedPanelTheme.rawValue, forKey: "unifiedPanelTheme")
        defaults.set(reminderCharacterSelection.storedString, forKey: "reminderCharacterSelection")
        defaults.set(restReminderFigureStyle.rawValue, forKey: "restReminderFigureStyle")
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
