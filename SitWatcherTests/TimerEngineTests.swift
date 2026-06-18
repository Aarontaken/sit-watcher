import XCTest
@testable import SitWatcher

final class TimerEngineTests: XCTestCase {

    var state: AppState!
    var settings: Settings!
    var engine: TimerEngine!
    var defaults: UserDefaults!
    var now: Date!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-timer")!
        defaults.removePersistentDomain(forName: "test-timer")
        settings = Settings(defaults: defaults)
        settings.reminderInterval = 10
        state = AppState()
        now = Date(timeIntervalSinceReferenceDate: 1_000)
        engine = TimerEngine(state: state, settings: settings, defaults: defaults, now: { self.now })
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

    func testStartRestoresRunningCountdownAfterRelaunch() {
        engine.start()
        state.remainingSeconds = 7
        engine.persistForShutdown()

        now = now.addingTimeInterval(3)
        state = AppState()
        engine = TimerEngine(state: state, settings: settings, defaults: defaults, now: { self.now })
        engine.start()

        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.remainingSeconds, 4, accuracy: 0.1)
        XCTAssertEqual(state.totalSeconds, 10)
    }

    func testStartRestoresPausedCountdownAfterRelaunch() {
        engine.start()
        state.remainingSeconds = 6
        engine.pause()
        engine.persistForShutdown()

        now = now.addingTimeInterval(3)
        state = AppState()
        engine = TimerEngine(state: state, settings: settings, defaults: defaults, now: { self.now })
        engine.start()

        XCTAssertEqual(state.timerPhase, .paused)
        XCTAssertEqual(state.remainingSeconds, 6, accuracy: 0.1)
        XCTAssertEqual(state.totalSeconds, 10)
    }

    func testStartCompletesExpiredSavedCountdownAfterRelaunch() {
        engine.start()
        state.remainingSeconds = 2
        engine.persistForShutdown()

        let expectation = expectation(description: "expired saved countdown completes")
        now = now.addingTimeInterval(3)
        state = AppState()
        engine = TimerEngine(state: state, settings: settings, defaults: defaults, now: { self.now })
        engine.onTimerComplete = { expectation.fulfill() }
        engine.start()

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(state.remainingSeconds, 0, accuracy: 0.1)
    }

    func testStartIgnoresStaleSavedCountdownAfterRelaunch() {
        engine.start()
        state.remainingSeconds = 7
        engine.persistForShutdown()

        now = now.addingTimeInterval(25 * 60 * 60)
        state = AppState()
        engine = TimerEngine(state: state, settings: settings, defaults: defaults, now: { self.now })
        engine.start()

        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 0.1)
        XCTAssertEqual(state.totalSeconds, 10)
    }
}
