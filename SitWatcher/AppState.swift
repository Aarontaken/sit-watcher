import Foundation
import Observation

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

@Observable
final class AppState {
    var timerPhase: TimerPhase = .running
    var remainingSeconds: TimeInterval = 0
    var totalSeconds: TimeInterval = 0
    var reminderLevel: ReminderLevel = .none
    var snoozedThisCycle: Bool = false

    var restCount: Int = 0
    var interruptCount: Int = 0
    var focusSeconds: TimeInterval = 0
    var showSettings: Bool = false

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
        case .running: return reminderLevel == .none ? "专注中" : "提醒中"
        case .paused: return "已暂停"
        case .idle: return "已离开"
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
