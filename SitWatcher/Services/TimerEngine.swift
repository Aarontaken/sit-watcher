import Foundation

final class TimerEngine {
    private let state: AppState
    private let settings: Settings
    private let defaults: UserDefaults
    private let now: () -> Date
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0
    private let maximumSavedCountdownAge: TimeInterval = 24 * 60 * 60
    private enum PersistenceKey {
        static let phase = "timerSnapshot.phase"
        static let remainingSeconds = "timerSnapshot.remainingSeconds"
        static let totalSeconds = "timerSnapshot.totalSeconds"
        static let savedAt = "timerSnapshot.savedAt"
    }

    var onTimerComplete: (() -> Void)?

    init(state: AppState, settings: Settings, defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.state = state
        self.settings = settings
        self.defaults = defaults
        self.now = now
    }

    func start(restoringSavedState: Bool = true) {
        if restoringSavedState, restoreSavedCountdown() {
            startTickingIfNeeded()
            return
        }

        startFresh()
    }

    private func startFresh() {
        state.totalSeconds = settings.reminderInterval
        state.remainingSeconds = settings.reminderInterval
        state.timerPhase = .running
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        persistForShutdown()
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
        persistForShutdown()
    }

    func resume() {
        guard state.timerPhase == .paused else { return }
        state.timerPhase = .running
        persistForShutdown()
        startTicking()
    }

    func reset() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        clearSavedCountdown()
        start(restoringSavedState: false)
    }

    func skip() {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = false
        clearSavedCountdown()
        start(restoringSavedState: false)
    }

    func enterIdle() {
        stop()
        state.timerPhase = .idle
        clearSavedCountdown()
    }

    func exitIdle() {
        start(restoringSavedState: false)
    }

    func snooze(duration: TimeInterval) {
        stop()
        state.reminderLevel = .none
        state.snoozedThisCycle = true
        state.totalSeconds = duration
        state.remainingSeconds = duration
        state.timerPhase = .running
        persistForShutdown()
        startTicking()
    }

    func persistForShutdown() {
        guard state.timerPhase == .running || state.timerPhase == .paused else {
            clearSavedCountdown()
            return
        }

        defaults.set(state.timerPhase.persistenceValue, forKey: PersistenceKey.phase)
        defaults.set(state.remainingSeconds, forKey: PersistenceKey.remainingSeconds)
        defaults.set(state.totalSeconds, forKey: PersistenceKey.totalSeconds)
        defaults.set(now(), forKey: PersistenceKey.savedAt)
        defaults.synchronize()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func startTickingIfNeeded() {
        guard state.timerPhase == .running else { return }
        startTicking()
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

    private func restoreSavedCountdown() -> Bool {
        guard
            let phaseValue = defaults.string(forKey: PersistenceKey.phase),
            let savedPhase = TimerPhase(persistenceValue: phaseValue),
            let savedAt = defaults.object(forKey: PersistenceKey.savedAt) as? Date
        else {
            return false
        }

        let savedTotal = defaults.double(forKey: PersistenceKey.totalSeconds)
        let savedRemaining = defaults.double(forKey: PersistenceKey.remainingSeconds)
        guard savedTotal > 0, savedRemaining > 0 else {
            clearSavedCountdown()
            return false
        }

        let savedAge = now().timeIntervalSince(savedAt)
        guard savedAge >= 0, savedAge <= maximumSavedCountdownAge else {
            clearSavedCountdown()
            return false
        }

        state.totalSeconds = savedTotal
        state.remainingSeconds = savedPhase == .running
            ? max(0, savedRemaining - savedAge)
            : savedRemaining
        state.timerPhase = savedPhase
        state.reminderLevel = .none

        if state.remainingSeconds <= 0 {
            clearSavedCountdown()
            onTimerComplete?()
        } else {
            persistForShutdown()
        }

        return true
    }

    private func clearSavedCountdown() {
        defaults.removeObject(forKey: PersistenceKey.phase)
        defaults.removeObject(forKey: PersistenceKey.remainingSeconds)
        defaults.removeObject(forKey: PersistenceKey.totalSeconds)
        defaults.removeObject(forKey: PersistenceKey.savedAt)
    }
}

private extension TimerPhase {
    var persistenceValue: String {
        switch self {
        case .running:
            return "running"
        case .paused:
            return "paused"
        case .idle:
            return "idle"
        }
    }

    init?(persistenceValue: String) {
        switch persistenceValue {
        case "running":
            self = .running
        case "paused":
            self = .paused
        case "idle":
            self = .idle
        default:
            return nil
        }
    }
}
