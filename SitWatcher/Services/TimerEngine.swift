import Foundation

final class TimerEngine {
    private let state: AppState
    private let settings: Settings
    private let defaults: UserDefaults
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0
    private enum PersistenceKey {
        static let phase = "timerSnapshot.phase"
        static let remainingSeconds = "timerSnapshot.remainingSeconds"
        static let totalSeconds = "timerSnapshot.totalSeconds"
        static let savedAt = "timerSnapshot.savedAt"
        static let appBuild = "timerSnapshot.appBuild"
    }

    var onTimerComplete: (() -> Void)?

    init(
        state: AppState,
        settings: Settings,
        defaults: UserDefaults = .standard
    ) {
        self.state = state
        self.settings = settings
        self.defaults = defaults
    }

    func start() {
        clearSavedCountdown()
        startFresh()
    }

    private func startFresh() {
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
        clearSavedCountdown()
        start()
    }

    func skip() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        clearSavedCountdown()
        start()
    }

    func enterIdle() {
        stop()
        state.timerPhase = .idle
        clearSavedCountdown()
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
            stop()
            clearSavedCountdown()
            onTimerComplete?()
        }
    }

    private func clearSavedCountdown() {
        defaults.removeObject(forKey: PersistenceKey.phase)
        defaults.removeObject(forKey: PersistenceKey.remainingSeconds)
        defaults.removeObject(forKey: PersistenceKey.totalSeconds)
        defaults.removeObject(forKey: PersistenceKey.savedAt)
        defaults.removeObject(forKey: PersistenceKey.appBuild)
    }
}
