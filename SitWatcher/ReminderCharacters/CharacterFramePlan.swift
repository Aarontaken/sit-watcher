import Foundation

struct CharacterFramePlan: Equatable {
    let frameCount: Int
    let frameInterval: TimeInterval
    let duration: TimeInterval
    let sampleTimes: [TimeInterval]

    static func make(
        sourceDuration: TimeInterval?,
        requestedStart: TimeInterval,
        sourceKind: CustomCharacterSourceKind
    ) -> CharacterFramePlan {
        if sourceKind == .stillImage {
            return CharacterFramePlan(frameCount: 1, frameInterval: 1, duration: 0, sampleTimes: [0])
        }

        let fullDuration = max(0, sourceDuration ?? CustomReminderCharacter.maxDuration)
        let requested = max(0, requestedStart)
        let start = requested < fullDuration
            ? requested
            : max(0, fullDuration - min(CustomReminderCharacter.maxDuration, fullDuration))
        let available = max(0, fullDuration - start)
        let duration = min(CustomReminderCharacter.maxDuration, available)
        let frameInterval = 1.0 / 15.0
        let count = min(CustomReminderCharacter.maxFrameCount, max(1, Int(ceil(duration / frameInterval))))
        let sampleTimes = (0..<count).map { index in
            start + Double(index) * frameInterval
        }
        return CharacterFramePlan(frameCount: count, frameInterval: frameInterval, duration: duration, sampleTimes: sampleTimes)
    }

    static func clampedCrop(_ crop: CharacterCrop) -> CharacterCrop {
        let scale = max(0.5, min(crop.scale, 4))
        let maxOffset = max(0, scale - 1)
        return CharacterCrop(
            scale: scale,
            offsetX: min(max(crop.offsetX, -maxOffset), maxOffset),
            offsetY: min(max(crop.offsetY, -maxOffset), maxOffset),
            shape: crop.shape
        )
    }
}
