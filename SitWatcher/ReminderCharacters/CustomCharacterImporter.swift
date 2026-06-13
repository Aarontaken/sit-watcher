import AppKit
import AVFoundation
import Foundation
import ImageIO

struct CustomCharacterImporter {
    let store: CustomCharacterStore
    private let fileManager: FileManager

    init(store: CustomCharacterStore = CustomCharacterStore(), fileManager: FileManager = .default) {
        self.store = store
        self.fileManager = fileManager
    }

    func importCharacter(
        existingCharacter: CustomReminderCharacter? = nil,
        sourceURL: URL,
        name: String,
        crop: CharacterCrop,
        videoStartTime: TimeInterval?
    ) async throws -> CustomReminderCharacter {
        let id = existingCharacter?.id ?? UUID()
        let tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("SitWatcherCustomCharacterImport", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let tempFrames = tempRoot.appendingPathComponent("frames", isDirectory: true)

        do {
            try fileManager.createDirectory(at: tempFrames, withIntermediateDirectories: true)

            let sourceKind = try detectSourceKind(sourceURL: sourceURL)
            let sourceFilename = Self.sourceFilename(for: sourceURL)
            try fileManager.copyItem(at: sourceURL, to: tempRoot.appendingPathComponent(sourceFilename))

            let plan = CharacterFramePlan.make(
                sourceDuration: try await sourceDuration(for: sourceURL, kind: sourceKind),
                requestedStart: sourceKind == .video ? (videoStartTime ?? 0) : 0,
                sourceKind: sourceKind
            )
            let frames = try await renderedFrames(sourceURL: sourceURL, kind: sourceKind, plan: plan, crop: crop)
            guard frames.isEmpty == false else { throw CocoaError(.fileReadCorruptFile) }

            for (index, image) in frames.enumerated() {
                try writePNG(image, to: tempFrames.appendingPathComponent(String(format: "frame-%03d.png", index)))
            }
            try writePNG(frames[0], to: tempRoot.appendingPathComponent("preview.png"))

            let now = Date()
            let character = CustomReminderCharacter(
                id: id,
                name: normalizedName(name),
                sourceKind: sourceKind,
                sourceFilename: sourceFilename,
                createdAt: existingCharacter?.createdAt ?? now,
                updatedAt: now,
                frameCount: frames.count,
                frameInterval: sourceKind == .stillImage ? 1 : plan.frameInterval,
                crop: CharacterFramePlan.clampedCrop(crop),
                videoStartTime: sourceKind == .video ? plan.sampleTimes.first : nil
            )
            try writeManifest(character, in: tempRoot)
            try moveCompletedPackage(from: tempRoot, id: id)
            return character
        } catch {
            try? fileManager.removeItem(at: tempRoot)
            throw error
        }
    }

    private func detectSourceKind(sourceURL: URL) throws -> CustomCharacterSourceKind {
        switch sourceURL.pathExtension.lowercased() {
        case "mov", "mp4", "m4v":
            return .video
        case "gif", "apng", "webp":
            return .animatedImage
        case "png", "jpg", "jpeg", "heic":
            if Self.imageSourceIsAnimated(sourceURL) {
                return .animatedImage
            }
            return .stillImage
        default:
            throw CocoaError(.fileReadUnsupportedScheme)
        }
    }

    private func sourceDuration(for sourceURL: URL, kind: CustomCharacterSourceKind) async throws -> TimeInterval? {
        switch kind {
        case .stillImage:
            return nil
        case .animatedImage:
            guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return Self.animatedImageDuration(source)
        case .video:
            let asset = AVURLAsset(url: sourceURL)
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : nil
        }
    }

    private func renderedFrames(
        sourceURL: URL,
        kind: CustomCharacterSourceKind,
        plan: CharacterFramePlan,
        crop: CharacterCrop
    ) async throws -> [NSImage] {
        switch kind {
        case .stillImage:
            guard let image = NSImage(contentsOf: sourceURL) else { throw CocoaError(.fileReadCorruptFile) }
            return [Self.render(image: image, crop: crop)]
        case .animatedImage:
            return try animatedImageFrames(sourceURL: sourceURL, plan: plan, crop: crop)
        case .video:
            return try await videoFrames(sourceURL: sourceURL, plan: plan, crop: crop)
        }
    }

    private func animatedImageFrames(sourceURL: URL, plan: CharacterFramePlan, crop: CharacterCrop) throws -> [NSImage] {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let imageCount = CGImageSourceGetCount(source)
        guard imageCount > 0 else { throw CocoaError(.fileReadCorruptFile) }

        let timeline = Self.animatedImageTimeline(source)
        return try plan.sampleTimes.map { time in
            let sourceIndex = Self.frameIndex(at: time, timeline: timeline)
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, min(sourceIndex, imageCount - 1), nil) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return Self.render(image: NSImage(cgImage: cgImage, size: .zero), crop: crop)
        }
    }

    private func videoFrames(sourceURL: URL, plan: CharacterFramePlan, crop: CharacterCrop) async throws -> [NSImage] {
        let asset = AVURLAsset(url: sourceURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        return try plan.sampleTimes.map { time in
            let cgImage = try generator.copyCGImage(at: CMTime(seconds: time, preferredTimescale: 600), actualTime: nil)
            return Self.render(image: NSImage(cgImage: cgImage, size: .zero), crop: crop)
        }
    }

    static func render(image: NSImage, crop: CharacterCrop) -> NSImage {
        let size = CGSize(width: CustomReminderCharacter.frameSize, height: CustomReminderCharacter.frameSize)
        let output = NSImage(size: size)
        output.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let clamped = CharacterFramePlan.clampedCrop(crop)
        let imageSize = image.size.width > 0 && image.size.height > 0 ? image.size : size
        let fillScale = max(size.width / imageSize.width, size.height / imageSize.height) * clamped.scale
        let drawSize = CGSize(width: imageSize.width * fillScale, height: imageSize.height * fillScale)
        let origin = CGPoint(
            x: (size.width - drawSize.width) / 2 + clamped.offsetX * size.width / 2,
            y: (size.height - drawSize.height) / 2 - clamped.offsetY * size.height / 2
        )

        let path: NSBezierPath
        switch clamped.shape {
        case .circle:
            path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
        case .roundedRectangle:
            path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 72, yRadius: 72)
        case .square:
            path = NSBezierPath(rect: NSRect(origin: .zero, size: size))
        }
        path.addClip()
        image.draw(in: NSRect(origin: origin, size: drawSize), from: .zero, operation: .sourceOver, fraction: 1)
        output.unlockFocus()
        return output
    }

    private func writePNG(_ image: NSImage, to url: URL) throws {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
    }

    private func writeManifest(_ character: CustomReminderCharacter, in tempRoot: URL) throws {
        let manifestRoot = tempRoot.appendingPathComponent("manifest-staging", isDirectory: true)
        let tempStore = CustomCharacterStore(rootURL: manifestRoot, fileManager: fileManager)
        try tempStore.saveManifest(character)
        let packageURL = tempStore.packageURL(for: character.id)
        let manifestURL = packageURL.appendingPathComponent("manifest.json")
        try fileManager.moveItem(at: manifestURL, to: tempRoot.appendingPathComponent("manifest.json"))
        try? fileManager.removeItem(at: manifestRoot)
    }

    private func moveCompletedPackage(from tempRoot: URL, id: UUID) throws {
        let finalURL = store.packageURL(for: id)
        let backupURL = finalURL.deletingLastPathComponent()
            .appendingPathComponent(".\(id.uuidString)-backup-\(UUID().uuidString)", isDirectory: true)
        var hasBackup = false

        try fileManager.createDirectory(at: finalURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        do {
            if fileManager.fileExists(atPath: finalURL.path) {
                try fileManager.moveItem(at: finalURL, to: backupURL)
                hasBackup = true
            }
            try fileManager.moveItem(at: tempRoot, to: finalURL)
            if hasBackup {
                try? fileManager.removeItem(at: backupURL)
            }
        } catch {
            if hasBackup,
               fileManager.fileExists(atPath: finalURL.path) == false,
               fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.moveItem(at: backupURL, to: finalURL)
            }
            throw error
        }
    }

    private func normalizedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Custom Character" : trimmed
    }

    private static func sourceFilename(for sourceURL: URL) -> String {
        let ext = sourceURL.pathExtension.lowercased()
        return "source.\(ext.isEmpty ? "dat" : ext)"
    }

    private static func animatedImageDuration(_ source: CGImageSource) -> TimeInterval {
        let timeline = animatedImageTimeline(source)
        return timeline.last?.end ?? CustomReminderCharacter.maxDuration
    }

    private static func imageSourceIsAnimated(_ sourceURL: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(source) > 1 else {
            return false
        }

        return (0..<CGImageSourceGetCount(source)).contains { index in
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
                return false
            }
            return delay(
                in: properties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
                unclampedKey: kCGImagePropertyGIFUnclampedDelayTime,
                clampedKey: kCGImagePropertyGIFDelayTime
            ) != nil || delay(
                in: properties[kCGImagePropertyPNGDictionary] as? [CFString: Any],
                unclampedKey: kCGImagePropertyAPNGUnclampedDelayTime,
                clampedKey: kCGImagePropertyAPNGDelayTime
            ) != nil || delay(
                in: properties[kCGImagePropertyWebPDictionary] as? [CFString: Any],
                unclampedKey: kCGImagePropertyWebPUnclampedDelayTime,
                clampedKey: kCGImagePropertyWebPDelayTime
            ) != nil
        }
    }

    private static func animatedImageTimeline(_ source: CGImageSource) -> [(end: TimeInterval, index: Int)] {
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return [] }

        var elapsed: TimeInterval = 0
        return (0..<count).map { index in
            elapsed += animatedImageFrameDelay(source, index: index)
            return (end: elapsed, index: index)
        }
    }

    private static func animatedImageFrameDelay(_ source: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return 1.0 / 15.0
        }
        let delay = Self.delay(
            in: properties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
            unclampedKey: kCGImagePropertyGIFUnclampedDelayTime,
            clampedKey: kCGImagePropertyGIFDelayTime
        ) ?? Self.delay(
            in: properties[kCGImagePropertyPNGDictionary] as? [CFString: Any],
            unclampedKey: kCGImagePropertyAPNGUnclampedDelayTime,
            clampedKey: kCGImagePropertyAPNGDelayTime
        ) ?? Self.delay(
            in: properties[kCGImagePropertyWebPDictionary] as? [CFString: Any],
            unclampedKey: kCGImagePropertyWebPUnclampedDelayTime,
            clampedKey: kCGImagePropertyWebPDelayTime
        ) ?? (1.0 / 15.0)
        return delay > 0 ? delay : (1.0 / 15.0)
    }

    private static func delay(
        in dictionary: [CFString: Any]?,
        unclampedKey: CFString,
        clampedKey: CFString
    ) -> TimeInterval? {
        guard let dictionary else { return nil }
        return dictionary[unclampedKey] as? TimeInterval ?? dictionary[clampedKey] as? TimeInterval
    }

    private static func frameIndex(at time: TimeInterval, timeline: [(end: TimeInterval, index: Int)]) -> Int {
        guard timeline.isEmpty == false else { return 0 }
        return timeline.first(where: { time < $0.end })?.index ?? timeline[timeline.count - 1].index
    }
}
