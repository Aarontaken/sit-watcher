import Foundation

final class ReminderEscalator {
    private let state: AppState
    private let settings: Settings
    private var escalationTimer: Timer?

    var onLevelChanged: ((ReminderLevel) -> Void)?

    init(state: AppState, settings: Settings) {
        self.state = state
        self.settings = settings
    }

    func start() {
        escalationTimer?.invalidate()
        setLevel(.l2)
        scheduleNextEscalation()
    }

    func stop() {
        escalationTimer?.invalidate()
        escalationTimer = nil
    }

    func dismiss() {
        stop()
        state.reminderLevel = .none
    }

    private func setLevel(_ level: ReminderLevel) {
        state.reminderLevel = level
        onLevelChanged?(level)
    }

    private func scheduleNextEscalation() {
        guard state.reminderLevel == .l2 else { return }

        escalationTimer = Timer.scheduledTimer(withTimeInterval: settings.l3Delay, repeats: false) { [weak self] _ in
            self?.setLevel(.l3)
            self?.state.interruptCount += 1
        }
    }
}
