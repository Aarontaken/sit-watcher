import Foundation
import Combine

enum TimerPhase {
    case running
    case paused
    case idle
}

enum ReminderLevel: Int, Comparable {
    case none = 0
    case l1 = 1
    case l2 = 2
    case l3 = 3

    static func < (lhs: ReminderLevel, rhs: ReminderLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

final class AppState: ObservableObject {
    @Published var timerPhase: TimerPhase = .running
    @Published var remainingSeconds: TimeInterval = 0
    @Published var totalSeconds: TimeInterval = 0
    @Published var reminderLevel: ReminderLevel = .none
    @Published var snoozedThisCycle: Bool = false

    @Published var restCount: Int = 0
    @Published var interruptCount: Int = 0
    @Published var focusSeconds: TimeInterval = 0

    private var lastResetDate: Date = .now

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalSeconds)
    }

    var formattedTime: String {
        let mins = Int(remainingSeconds) / 60
        let secs = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var statusLabel: String {
        switch timerPhase {
        case .running:
            return reminderLevel == .none ? L10n.text("status.focusing") : L10n.text("status.reminding")
        case .paused:
            return L10n.text("status.paused")
        case .idle:
            return L10n.text("status.away")
        }
    }

    func resetDailyStatsIfNeeded() {
        if !Calendar.current.isDateInToday(lastResetDate) {
            restCount = 0
            interruptCount = 0
            focusSeconds = 0
            lastResetDate = .now
        }
    }
}
