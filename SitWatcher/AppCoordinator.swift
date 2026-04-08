import AppKit

final class AppCoordinator {
    let appState = AppState()
    let settings = Settings.shared
    let timerEngine: TimerEngine
    let idleDetector: IdleDetector
    let escalator: ReminderEscalator
    let floatingWindow = FloatingWindowController()
    let overlayWindow = OverlayWindowController()

    init() {
        timerEngine = TimerEngine(state: appState, settings: settings)
        idleDetector = IdleDetector(mouseThreshold: settings.mouseMovementThreshold)
        escalator = ReminderEscalator(state: appState, settings: settings)
    }

    func start() {
        NotificationManager.shared.requestPermission()

        timerEngine.onTimerComplete = { [weak self] in
            guard let self else { return }
            let minutes = Int(self.settings.reminderInterval / 60)
            NotificationManager.shared.sendReminder(minutes: minutes)
            if self.settings.soundEnabled {
                NSSound(named: .init("Blow"))?.play()
            }
            self.escalator.start()
        }

        escalator.onLevelChanged = { [weak self] level in
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

        idleDetector.onIdleStateChanged = { [weak self] isIdle in
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

        timerEngine.start()
        idleDetector.start(idleThreshold: settings.idleThreshold)
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
