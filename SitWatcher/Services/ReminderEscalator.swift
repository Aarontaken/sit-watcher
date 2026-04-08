import Foundation

@Observable
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
        setLevel(.l1)
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
        let delay: TimeInterval
        switch state.reminderLevel {
        case .none: return
        case .l1: delay = settings.l2Delay
        case .l2: delay = settings.l3Delay
        case .l3: return
        }

        escalationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.escalate()
        }
    }

    private func escalate() {
        switch state.reminderLevel {
        case .none: break
        case .l1:
            setLevel(.l2)
            scheduleNextEscalation()
        case .l2:
            setLevel(.l3)
            state.interruptCount += 1
        case .l3:
            break
        }
    }
}
