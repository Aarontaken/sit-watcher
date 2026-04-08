import Foundation

@Observable
final class TimerEngine {
    private let state: AppState
    private let settings: Settings
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0

    var onTimerComplete: (() -> Void)?

    init(state: AppState, settings: Settings) {
        self.state = state
        self.settings = settings
    }

    func start() {
        state.totalSeconds = settings.reminderInterval
        state.remainingSeconds = settings.reminderInterval
        state.timerPhase = .running
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        startTicking()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        state.timerPhase = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard state.timerPhase == .paused else { return }
        state.timerPhase = .running
        startTicking()
    }

    func reset() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        start()
    }

    func skip() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        start()
    }

    func enterIdle() {
        stop()
        state.timerPhase = .idle
    }

    func exitIdle() {
        start()
    }

    func snooze(duration: TimeInterval) {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = true
        state.totalSeconds = duration
        state.remainingSeconds = duration
        state.timerPhase = .running
        startTicking()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard state.timerPhase == .running else { return }

        state.remainingSeconds = max(0, state.remainingSeconds - tickInterval)
        state.focusSeconds += tickInterval
        state.resetDailyStatsIfNeeded()

        if state.remainingSeconds <= 0 && state.reminderLevel == .none {
            onTimerComplete?()
        }
    }
}
