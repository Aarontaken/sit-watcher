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

        let s2 = Settings(defaults: defaults)
        XCTAssertEqual(s2.reminderInterval, 45 * 60)
        XCTAssertFalse(s2.soundEnabled)
        XCTAssertEqual(s2.uiLanguage, .english)
        XCTAssertEqual(s2.uiPanelAppearance, .light)
    }
}
