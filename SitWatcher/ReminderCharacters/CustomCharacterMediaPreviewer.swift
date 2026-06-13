import AppKit
import AVFoundation
import ImageIO

@MainActor
enum CustomCharacterMediaPreviewer {
    static func previewImage(from url: URL, startTime: TimeInterval) async throws -> NSImage {
        if ["mov", "mp4", "m4v"].contains(url.pathExtension.lowercased()) {
            let asset = AVURLAsset(url: url)
            let generator = CustomCharacterVideoFrameGenerator.makeGenerator(asset: asset)
            let cgImage = try generator.copyCGImage(
                at: CMTime(seconds: max(0, startTime), preferredTimescale: 600),
                actualTime: nil
            )
            return NSImage(cgImage: cgImage, size: .zero)
        }

        if let image = NSImage(contentsOf: url) {
            return image
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return NSImage(cgImage: cgImage, size: .zero)
    }
}

enum CustomCharacterVideoFrameGenerator {
    static func makeGenerator(asset: AVAsset) -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        return generator
    }
}
