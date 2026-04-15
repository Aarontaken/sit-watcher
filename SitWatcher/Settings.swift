import Foundation
import Combine
import ServiceManagement

final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults: UserDefaults

    var reminderInterval: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(reminderInterval, forKey: "reminderInterval") }
    }

    var l2Delay: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(l2Delay, forKey: "l2Delay") }
    }

    var l3Delay: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(l3Delay, forKey: "l3Delay") }
    }

    var idleThreshold: TimeInterval {
        willSet { objectWillChange.send() }
        didSet { defaults.set(idleThreshold, forKey: "idleThreshold") }
    }

    var mouseMovementThreshold: Double {
        willSet { objectWillChange.send() }
        didSet { defaults.set(mouseMovementThreshold, forKey: "mouseMovementThreshold") }
    }

    var soundEnabled: Bool {
        willSet { objectWillChange.send() }
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    var launchAtLogin: Bool {
        willSet { objectWillChange.send() }
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            "reminderInterval": 30.0 * 60,
            "l2Delay": 2.0 * 60,
            "l3Delay": 2.0 * 60,
            "idleThreshold": 5.0 * 60,
            "mouseMovementThreshold": 10.0,
            "soundEnabled": true,
            "launchAtLogin": false,
        ])

        let interval = defaults.double(forKey: "reminderInterval")
        self.reminderInterval = interval > 0 ? interval : 30 * 60

        let l2 = defaults.double(forKey: "l2Delay")
        self.l2Delay = l2 > 0 ? l2 : 2 * 60

        let l3 = defaults.double(forKey: "l3Delay")
        self.l3Delay = l3 > 0 ? l3 : 2 * 60

        let idle = defaults.double(forKey: "idleThreshold")
        self.idleThreshold = idle > 0 ? idle : 5 * 60

        let mouse = defaults.double(forKey: "mouseMovementThreshold")
        self.mouseMovementThreshold = mouse > 0 ? mouse : 10.0

        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        defaults.set(reminderInterval, forKey: "reminderInterval")
        defaults.set(l2Delay, forKey: "l2Delay")
        defaults.set(l3Delay, forKey: "l3Delay")
        defaults.set(idleThreshold, forKey: "idleThreshold")
        defaults.set(mouseMovementThreshold, forKey: "mouseMovementThreshold")
        defaults.set(soundEnabled, forKey: "soundEnabled")
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
