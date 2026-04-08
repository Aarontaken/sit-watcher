import Foundation
import Observation
import ServiceManagement

@Observable
final class Settings {
    static var shared = Settings()

    private let defaults: UserDefaults

    var reminderInterval: TimeInterval {
        didSet { defaults.set(reminderInterval, forKey: "reminderInterval") }
    }

    var l2Delay: TimeInterval {
        didSet { defaults.set(l2Delay, forKey: "l2Delay") }
    }

    var l3Delay: TimeInterval {
        didSet { defaults.set(l3Delay, forKey: "l3Delay") }
    }

    var idleThreshold: TimeInterval {
        didSet { defaults.set(idleThreshold, forKey: "idleThreshold") }
    }

    var mouseMovementThreshold: Double {
        didSet { defaults.set(mouseMovementThreshold, forKey: "mouseMovementThreshold") }
    }

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let hasRun = defaults.bool(forKey: "hasRun")

        if hasRun {
            self.reminderInterval = defaults.double(forKey: "reminderInterval")
            self.l2Delay = defaults.double(forKey: "l2Delay")
            self.l3Delay = defaults.double(forKey: "l3Delay")
            self.idleThreshold = defaults.double(forKey: "idleThreshold")
            self.mouseMovementThreshold = defaults.double(forKey: "mouseMovementThreshold")
            self.soundEnabled = defaults.bool(forKey: "soundEnabled")
            self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        } else {
            self.reminderInterval = 30 * 60
            self.l2Delay = 2 * 60
            self.l3Delay = 2 * 60
            self.idleThreshold = 5 * 60
            self.mouseMovementThreshold = 10.0
            self.soundEnabled = true
            self.launchAtLogin = false
            defaults.set(true, forKey: "hasRun")
        }
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
