import SwiftUI

@main
struct SitWatcherApp: App {
    @State private var appState = AppState()
    @State private var settings = Settings.shared
    @State private var timerEngine: TimerEngine?
    @State private var idleDetector: IdleDetector?
    @State private var escalator: ReminderEscalator?
    @State private var showSettings = false

    private let floatingWindow = FloatingWindowController()
    private let overlayWindow = OverlayWindowController()

    var body: some Scene {
        MenuBarExtra {
            if showSettings {
                SettingsView(settings: settings)
            } else {
                MenuBarPanel(
                    state: appState,
                    onPauseToggle: togglePause,
                    onSkip: skip,
                    onReset: reset,
                    onOpenSettings: { showSettings = true },
                    onQuit: { NSApplication.shared.terminate(nil) }
                )
            }
        } label: {
            Image(systemName: menuBarIcon)
                .symbolEffect(.pulse, options: .repeating, isActive: appState.reminderLevel == .l1)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: showSettings) { _, newValue in
            if !newValue { }
        }
        .onAppear {
            setupEngine()
        }
    }

    private var menuBarIcon: String {
        switch (appState.timerPhase, appState.reminderLevel) {
        case (.paused, _): return "figure.stand"
        case (.idle, _): return "figure.stand"
        case (_, .none): return "figure.stand"
        case (_, .l1): return "figure.walk"
        case (_, .l2): return "figure.walk"
        case (_, .l3): return "figure.run"
        }
    }

    private func setupEngine() {
        NotificationManager.shared.requestPermission()

        let engine = TimerEngine(state: appState, settings: settings)
        let detector = IdleDetector(mouseThreshold: settings.mouseMovementThreshold)
        let esc = ReminderEscalator(state: appState, settings: settings)

        engine.onTimerComplete = { [esc] in
            let minutes = Int(settings.reminderInterval / 60)
            NotificationManager.shared.sendReminder(minutes: minutes)
            if settings.soundEnabled {
                NSSound(named: .init("Blow"))?.play()
            }
            esc.start()
        }

        esc.onLevelChanged = { [floatingWindow, overlayWindow] level in
            DispatchQueue.main.async {
                let minutes = Int(settings.reminderInterval / 60)
                switch level {
                case .none:
                    floatingWindow.close()
                    overlayWindow.close()
                    NotificationManager.shared.clearAll()
                case .l1:
                    break
                case .l2:
                    floatingWindow.show(
                        sittingMinutes: minutes,
                        canSnooze: !appState.snoozedThisCycle,
                        onConfirm: { confirmRest(engine: engine, escalator: esc) },
                        onSnooze: { snooze(engine: engine, escalator: esc) }
                    )
                case .l3:
                    floatingWindow.close()
                    overlayWindow.show(sittingMinutes: minutes) {
                        confirmRest(engine: engine, escalator: esc)
                    }
                }
            }
        }

        detector.onIdleStateChanged = { [engine] isIdle in
            DispatchQueue.main.async {
                if isIdle {
                    engine.enterIdle()
                    esc.dismiss()
                    floatingWindow.close()
                    overlayWindow.close()
                } else {
                    engine.exitIdle()
                }
            }
        }

        engine.start()
        detector.start(idleThreshold: settings.idleThreshold)

        self.timerEngine = engine
        self.idleDetector = detector
        self.escalator = esc
    }

    private func confirmRest(engine: TimerEngine, escalator: ReminderEscalator) {
        escalator.dismiss()
        floatingWindow.close()
        overlayWindow.close()
        NotificationManager.shared.clearAll()
        appState.restCount += 1
        engine.reset()
    }

    private func snooze(engine: TimerEngine, escalator: ReminderEscalator) {
        escalator.dismiss()
        floatingWindow.close()
        engine.snooze(duration: 5 * 60)
    }

    private func togglePause() {
        guard let engine = timerEngine else { return }
        if appState.timerPhase == .paused {
            engine.resume()
        } else {
            engine.pause()
        }
    }

    private func skip() {
        timerEngine?.skip()
    }

    private func reset() {
        timerEngine?.reset()
        escalator?.dismiss()
        floatingWindow.close()
        overlayWindow.close()
        NotificationManager.shared.clearAll()
    }
}
