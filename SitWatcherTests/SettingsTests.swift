import XCTest
@testable import SitWatcher

final class SettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-settings")!
        defaults.removePersistentDomain(forName: "test-settings")
        Settings.shared = Settings(defaults: defaults)
    }

    func testDefaultValues() {
        let s = Settings.shared
        XCTAssertEqual(s.reminderInterval, 30 * 60)
        XCTAssertEqual(s.l2Delay, 2 * 60)
        XCTAssertEqual(s.l3Delay, 2 * 60)
        XCTAssertEqual(s.idleThreshold, 5 * 60)
        XCTAssertEqual(s.mouseMovementThreshold, 10.0)
        XCTAssertTrue(s.soundEnabled)
        XCTAssertFalse(s.launchAtLogin)
    }

    func testPersistence() {
        let defaults = UserDefaults(suiteName: "test-persistence")!
        defaults.removePersistentDomain(forName: "test-persistence")
        let s = Settings(defaults: defaults)
        s.reminderInterval = 45 * 60
        s.soundEnabled = false

        let s2 = Settings(defaults: defaults)
        XCTAssertEqual(s2.reminderInterval, 45 * 60)
        XCTAssertFalse(s2.soundEnabled)

        defaults.removePersistentDomain(forName: "test-persistence")
    }
}
