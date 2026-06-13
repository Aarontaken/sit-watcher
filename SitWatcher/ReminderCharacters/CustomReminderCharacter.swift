import Foundation

enum CustomCharacterSourceKind: String, Codable, Equatable {
    case stillImage
    case animatedImage
    case video
}

enum CustomCharacterCropShape: String, Codable, Equatable, CaseIterable, Identifiable {
    case none
    case circle
    case roundedRectangle
    case square

    var id: String { rawValue }
}

struct CharacterCrop: Codable, Equatable {
    var scale: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var shape: CustomCharacterCropShape
}

struct CustomReminderCharacter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var sourceKind: CustomCharacterSourceKind
    var sourceFilename: String
    var createdAt: Date
    var updatedAt: Date
    var frameCount: Int
    var frameInterval: TimeInterval
    var crop: CharacterCrop
    var videoStartTime: TimeInterval?

    static let frameSize = 512
    static let maxFrameCount = 45
    static let maxDuration: TimeInterval = 3
}
