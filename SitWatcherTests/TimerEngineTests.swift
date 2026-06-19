import XCTest
@testable import SitWatcher

final class TimerEngineTests: XCTestCase {

    var state: AppState!
    var settings: Settings!
    var engine: TimerEngine!
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-timer")!
        defaults.removePersistentDomain(forName: "test-timer")
        settings = Settings(defaults: defaults)
        settings.reminderInterval = 10
        state = AppState()
        engine = TimerEngine(state: state, settings: settings, defaults: defaults)
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

    func testStartIgnoresSavedCountdownFromPreviousLaunch() {
        defaults.set("22", forKey: "timerSnapshot.appBuild")
        defaults.set("running", forKey: "timerSnapshot.phase")
        defaults.set(7.0, forKey: "timerSnapshot.remainingSeconds")
        defaults.set(10.0, forKey: "timerSnapshot.totalSeconds")
        defaults.set(Date(timeIntervalSinceReferenceDate: 1_000), forKey: "timerSnapshot.savedAt")

        engine.start()

        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 0.1)
        XCTAssertEqual(state.totalSeconds, 10)
        XCTAssertNil(defaults.object(forKey: "timerSnapshot.phase"))
        XCTAssertNil(defaults.object(forKey: "timerSnapshot.remainingSeconds"))
        XCTAssertNil(defaults.object(forKey: "timerSnapshot.totalSeconds"))
        XCTAssertNil(defaults.object(forKey: "timerSnapshot.savedAt"))
        XCTAssertNil(defaults.object(forKey: "timerSnapshot.appBuild"))
    }

    func testStartIgnoresExpiredSavedCountdownFromPreviousLaunch() {
        defaults.set("22", forKey: "timerSnapshot.appBuild")
        defaults.set("running", forKey: "timerSnapshot.phase")
        defaults.set(2.0, forKey: "timerSnapshot.remainingSeconds")
        defaults.set(10.0, forKey: "timerSnapshot.totalSeconds")
        defaults.set(Date(timeIntervalSinceReferenceDate: 1_000), forKey: "timerSnapshot.savedAt")

        let expectation = expectation(description: "expired legacy countdown does not complete")
        expectation.isInverted = true
        engine.onTimerComplete = { expectation.fulfill() }
        engine.start()

        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(state.timerPhase, .running)
        XCTAssertEqual(state.remainingSeconds, 10, accuracy: 0.1)
        XCTAssertEqual(state.totalSeconds, 10)
    }
}
