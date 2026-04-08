import XCTest
@testable import SitWatcher

final class ReminderEscalatorTests: XCTestCase {

    var state: AppState!
    var settings: Settings!
    var escalator: ReminderEscalator!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-escalator")!
        defaults.removePersistentDomain(forName: "test-escalator")
        settings = Settings(defaults: defaults)
        settings.l2Delay = 2
        settings.l3Delay = 2
        state = AppState()
        escalator = ReminderEscalator(state: state, settings: settings)
    }

    override func tearDown() {
        escalator.stop()
        super.tearDown()
    }

    func testStartBeginsAtL1() {
        escalator.start()
        XCTAssertEqual(state.reminderLevel, .l1)
    }

    func testEscalatesToL2() {
        let expectation = expectation(description: "L2 reached")
        escalator.onLevelChanged = { level in
            if level == .l2 { expectation.fulfill() }
        }
        escalator.start()
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(state.reminderLevel, .l2)
    }

    func testEscalatesToL3() {
        let expectation = expectation(description: "L3 reached")
        escalator.onLevelChanged = { level in
            if level == .l3 { expectation.fulfill() }
        }
        escalator.start()
        wait(for: [expectation], timeout: 8)
        XCTAssertEqual(state.reminderLevel, .l3)
    }

    func testDismissResetsLevel() {
        escalator.start()
        escalator.dismiss()
        XCTAssertEqual(state.reminderLevel, .none)
    }
}
