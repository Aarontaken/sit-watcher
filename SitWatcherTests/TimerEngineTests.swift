import XCTest
@testable import SitWatcher

final class TimerEngineTests: XCTestCase {

    var state: AppState!
    var settings: Settings!
    var engine: TimerEngine!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test-timer")!
        defaults.removePersistentDomain(forName: "test-timer")
        settings = Settings(defaults: defaults)
        settings.reminderInterval = 10
        state = AppState()
        engine = TimerEngine(state: state, settings: settings)
    }

    override func tearDown() {
        engine.stop()
        super.tearDown()
    }

    func testInitialState() {
        engine.start()
        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 1)
        XCTAssertEqual(state.totalSeconds, 10)
    }

    func testPause() {
        engine.start()
        engine.pause()
        XCTAssertEqual(state.timerPhase, .paused)
    }

    func testResume() {
        engine.start()
        engine.pause()
        engine.resume()
        XCTAssertEqual(state.timerPhase, .running)
    }

    func testReset() {
        engine.start()
        state.remainingSeconds = 5
        engine.reset()
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 1)
        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.reminderLevel, .none)
        XCTAssertFalse(state.snoozedThisCycle)
    }

    func testSkip() {
        engine.start()
        state.remainingSeconds = 5
        engine.skip()
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 1)
        XCTAssertEqual(state.reminderLevel, .none)
    }

    func testTimerFiresCallback() {
        let expectation = expectation(description: "onTimerComplete called")
        engine.onTimerComplete = { expectation.fulfill() }
        engine.start()
        state.remainingSeconds = 0.5
        wait(for: [expectation], timeout: 3)
    }
}
