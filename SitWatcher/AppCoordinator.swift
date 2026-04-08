import AppKit
import Observation

@Observable
final class AppCoordinator {
    let appState = AppState()
    let settings = Settings.shared
    private(set) var timerEngine: TimerEngine!
    private(set) var idleDetector: IdleDetector!
    private(set) var escalator: ReminderEscalator!
    let floatingWindow = FloatingWindowController()
    let overlayWindow = OverlayWindowController()
    var showSettings = false
    var started = false

    func startIfNeeded() {
        guard !started else { return }
        started = true

        let engine = TimerEngine(state: appState, settings: settings)
        let detector = IdleDetector(mouseThreshold: settings.mouseMovementThreshold)
        let esc = ReminderEscalator(state: appState, settings: settings)

        self.timerEngine = engine
        self.idleDetector = detector
        self.escalator = esc

        NotificationManager.shared.requestPermission()

        engine.onTimerComplete = { [weak esc, weak self] in
            guard let esc, let self else { return }
            let minutes = Int(self.settings.reminderInterval / 60)
            NotificationManager.shared.sendReminder(minutes: minutes)
            if self.settings.soundEnabled {
                NSSound(named: .init("Blow"))?.play()
            }
            esc.start()
        }

        esc.onLevelChanged = { [weak self] level in
            guard let self else { return }
            DispatchQueue.main.async {
                let minutes = Int(self.settings.reminderInterval / 60)
                switch level {
                case .none:
                    self.floatingWindow.close()
                    self.overlayWindow.close()
                    NotificationManager.shared.clearAll()
                case .l1:
                    break
                case .l2:
                    self.floatingWindow.show(
                        sittingMinutes: minutes,
                        canSnooze: !self.appState.snoozedThisCycle,
                        onConfirm: { self.confirmRest() },
                        onSnooze: { self.snooze() }
                    )
                case .l3:
                    self.floatingWindow.close()
                    self.overlayWindow.show(sittingMinutes: minutes) {
                        self.confirmRest()
                    }
                }
            }
        }

        detector.onIdleStateChanged = { [weak self] isIdle in
            guard let self else { return }
            DispatchQueue.main.async {
                if isIdle {
                    self.timerEngine.enterIdle()
                    self.escalator.dismiss()
                    self.floatingWindow.close()
                    self.overlayWindow.close()
                } else {
                    self.timerEngine.exitIdle()
                }
            }
        }

        engine.start()
        detector.start(idleThreshold: settings.idleThreshold)
    }

    func confirmRest() {
        escalator.dismiss()
        floatingWindow.close()
        overlayWindow.close()
        NotificationManager.shared.clearAll()
        appState.restCount += 1
        timerEngine.reset()
    }

    func snooze() {
        escalator.dismiss()
        floatingWindow.close()
        timerEngine.snooze(duration: 5 * 60)
    }

    func togglePause() {
        if appState.timerPhase == .paused {
            timerEngine.resume()
        } else {
            timerEngine.pause()
        }
    }

    func skip() {
        timerEngine.skip()
    }

    func reset() {
        timerEngine.reset()
        escalator.dismiss()
        floatingWindow.close()
        overlayWindow.close()
        NotificationManager.shared.clearAll()
    }
}
