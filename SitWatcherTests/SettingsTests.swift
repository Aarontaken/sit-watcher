import XCTest
@testable import SitWatcher

final class SettingsTests: XCTestCase {

    private let suiteDefaultsName = "test-settings-default-values"

    override func tearDown() {
        UserDefaults(suiteName: suiteDefaultsName)?.removePersistentDomain(forName: suiteDefaultsName)
        super.tearDown()
    }

    func testDefaultValues() {
        let defaults = UserDefaults(suiteName: suiteDefaultsName)!
        defaults.removePersistentDomain(forName: suiteDefaultsName)

        let s = Settings(defaults: defaults)

        XCTAssertEqual(s.reminderInterval, 30 * 60)
        XCTAssertEqual(s.l2Delay, 2 * 60)
        XCTAssertEqual(s.l3Delay, 2 * 60)
        XCTAssertEqual(s.idleThreshold, 5 * 60)
        XCTAssertEqual(s.mouseMovementThreshold, 10.0)
        XCTAssertTrue(s.soundEnabled)
        XCTAssertFalse(s.launchAtLogin)
        XCTAssertEqual(s.uiLanguage, .system)
        XCTAssertEqual(s.uiPanelAppearance, .system)
        XCTAssertEqual(s.unifiedPanelTheme, .paper)
        XCTAssertEqual(s.restReminderFigureStyle, .line)
        XCTAssertEqual(s.reminderCharacterSelection, .builtIn(.line))
    }

    func testPersistence() {
        let persistenceName = "test-persistence"
        let defaults = UserDefaults(suiteName: persistenceName)!
        defaults.removePersistentDomain(forName: persistenceName)
        defer { defaults.removePersistentDomain(forName: persistenceName) }

        let s = Settings(defaults: defaults)
        s.reminderInterval = 45 * 60
        s.soundEnabled = false
        s.uiLanguage = .english
        s.uiPanelAppearance = .light
        s.unifiedPanelTheme = .dusk
        s.restReminderFigureStyle = .stretch
        s.reminderCharacterSelection = .builtIn(.stretch)

        let s2 = Settings(defaults: defaults)
        XCTAssertEqual(s2.reminderInterval, 45 * 60)
        XCTAssertFalse(s2.soundEnabled)
        XCTAssertEqual(s2.uiLanguage, .english)
        XCTAssertEqual(s2.uiPanelAppearance, .light)
        XCTAssertEqual(s2.unifiedPanelTheme, .dusk)
        XCTAssertEqual(s2.restReminderFigureStyle, .stretch)
        XCTAssertEqual(s2.reminderCharacterSelection, .builtIn(.stretch))
    }

    func testReminderCharacterSelectionMigratesLegacyFigureStyle() {
        let defaultsName = "test-character-selection-migration"
        let defaults = UserDefaults(suiteName: defaultsName)!
        defaults.removePersistentDomain(forName: defaultsName)
        defer { defaults.removePersistentDomain(forName: defaultsName) }

        defaults.set(RestReminderFigureStyle.pixelHydrate.rawValue, forKey: "restReminderFigureStyle")

        let settings = Settings(defaults: defaults)
        XCTAssertEqual(settings.reminderCharacterSelection, .builtIn(.pixelHydrate))
    }

    func testCustomReminderCharacterSelectionPersistsWithoutRewritingBuiltInStyle() {
        let defaultsName = "test-custom-character-selection-persistence"
        let defaults = UserDefaults(suiteName: defaultsName)!
        defaults.removePersistentDomain(forName: defaultsName)
        defer { defaults.removePersistentDomain(forName: defaultsName) }

        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let settings = Settings(defaults: defaults)
        settings.restReminderFigureStyle = .pixelJump
        settings.reminderCharacterSelection = .custom(id)

        let reloaded = Settings(defaults: defaults)
        XCTAssertEqual(reloaded.reminderCharacterSelection, .custom(id))
        XCTAssertEqual(reloaded.restReminderFigureStyle, .pixelJump)
        XCTAssertEqual(defaults.string(forKey: "reminderCharacterSelection"), "custom:\(id.uuidString)")
    }
}
