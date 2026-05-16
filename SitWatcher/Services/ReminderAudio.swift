import AppKit

/// Menu-bar foreground apps rarely deliver notification tones; `NSSound` plays reliably.
enum ReminderAudio {
    private static let cueName = NSSound.Name("Glass")

    static func playDeadlineCueIfEnabled(settings: Settings) {
        guard settings.soundEnabled else { return }
        if let sound = NSSound(named: cueName) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
