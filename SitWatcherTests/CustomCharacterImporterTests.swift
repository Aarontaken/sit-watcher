import AppKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import SitWatcher

final class CustomCharacterImporterTests: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SitWatcherImporterTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testImportStaticPNGCreatesPackagePreviewAndOneFrame() async throws {
        let imageURL = rootURL.appendingPathComponent("source.png")
        try Self.writePNG(color: .systemBlue, size: CGSize(width: 120, height: 80), to: imageURL)

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)
        let result = try await importer.importCharacter(
            sourceURL: imageURL,
            name: "Blue",
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: nil
        )

        XCTAssertEqual(result.name, "Blue")
        XCTAssertEqual(result.sourceKind, .stillImage)
        XCTAssertEqual(result.frameCount, 1)
        XCTAssertEqual(result.frameInterval, 1)
        XCTAssertEqual(result.sourceFilename, "source.png")
        XCTAssertNil(result.videoStartTime)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.sourceURL(for: result).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.previewURL(for: result.id).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.framesURL(for: result.id).appendingPathComponent("frame-000.png").path))
        let manifest = try store.loadManifest(id: result.id)
        XCTAssertEqual(manifest.id, result.id)
        XCTAssertEqual(manifest.name, result.name)
        XCTAssertEqual(manifest.sourceKind, result.sourceKind)
        XCTAssertEqual(manifest.sourceFilename, result.sourceFilename)
        XCTAssertEqual(manifest.frameCount, result.frameCount)
        XCTAssertEqual(manifest.frameInterval, result.frameInterval)
        XCTAssertEqual(manifest.crop, result.crop)
        XCTAssertEqual(manifest.createdAt.timeIntervalSince1970, result.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(manifest.updatedAt.timeIntervalSince1970, result.updatedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func testImportTrimsBlankNameAndClampsCrop() async throws {
        let imageURL = rootURL.appendingPathComponent("source.png")
        try Self.writePNG(color: .systemGreen, size: CGSize(width: 80, height: 80), to: imageURL)

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)
        let result = try await importer.importCharacter(
            sourceURL: imageURL,
            name: "   ",
            crop: CharacterCrop(scale: 12, offsetX: 9, offsetY: -9, shape: .square),
            videoStartTime: 12
        )

        XCTAssertEqual(result.name, "Custom Character")
        XCTAssertEqual(result.crop, CharacterCrop(scale: 4, offsetX: 3, offsetY: -3, shape: .square))
        XCTAssertNil(result.videoStartTime)
    }

    func testImportAnimatedGIFUsesFrameDelays() async throws {
        let gifURL = rootURL.appendingPathComponent("source.gif")
        try Self.writeAnimatedGIF(
            colors: [.systemBlue, .systemRed],
            delay: 0.5,
            size: CGSize(width: 64, height: 64),
            to: gifURL
        )

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)
        let result = try await importer.importCharacter(
            sourceURL: gifURL,
            name: "Animated",
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: nil
        )

        XCTAssertEqual(result.sourceKind, .animatedImage)
        XCTAssertEqual(result.sourceFilename, "source.gif")
        XCTAssertEqual(result.frameCount, 15)
        XCTAssertEqual(result.frameInterval, 1.0 / 15.0)
        XCTAssertNil(result.videoStartTime)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.framesURL(for: result.id).appendingPathComponent("frame-014.png").path))
    }

    func testImportAPNGWithPNGExtensionUsesAnimatedFrames() async throws {
        let apngURL = rootURL.appendingPathComponent("source.png")
        try Self.writeAnimatedPNG(
            colors: [.systemPurple, .systemOrange],
            delay: 0.5,
            size: CGSize(width: 64, height: 64),
            to: apngURL
        )

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)
        let result = try await importer.importCharacter(
            sourceURL: apngURL,
            name: "APNG",
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: nil
        )

        XCTAssertEqual(result.sourceKind, .animatedImage)
        XCTAssertEqual(result.sourceFilename, "source.png")
        XCTAssertGreaterThan(result.frameCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.framesURL(for: result.id).appendingPathComponent("frame-001.png").path))
    }

    func testRenderWithNoCropShapeKeepsFullFrameCorners() throws {
        let source = Self.image(color: .systemRed, size: CGSize(width: 64, height: 64))
        let crop = CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .none)

        let rendered = CustomCharacterImporter.render(image: source, crop: crop)
        let circleRendered = CustomCharacterImporter.render(
            image: source,
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle)
        )

        XCTAssertGreaterThan(Self.alpha(at: CGPoint(x: 1, y: 1), in: rendered), 0.9)
        XCTAssertLessThan(Self.alpha(at: CGPoint(x: 1, y: 1), in: circleRendered), 0.1)
    }

    func testVideoPreviewerCreatesPreviewImageForMovie() async throws {
        let videoURL = rootURL.appendingPathComponent("source.mp4")
        try Self.writeTestVideo(
            colors: [.systemBlue, .systemGreen, .systemOrange],
            frameRate: 3,
            size: CGSize(width: 64, height: 64),
            to: videoURL
        )

        let preview = try await CustomCharacterMediaPreviewer.previewImage(from: videoURL, startTime: 0)

        XCTAssertGreaterThan(preview.size.width, 0)
        XCTAssertGreaterThan(preview.size.height, 0)
    }

    func testVideoFrameGeneratorRequestsExactFrames() throws {
        let asset = AVURLAsset(url: rootURL.appendingPathComponent("source.mp4"))
        let generator = CustomCharacterVideoFrameGenerator.makeGenerator(asset: asset)

        XCTAssertEqual(generator.requestedTimeToleranceBefore, .zero)
        XCTAssertEqual(generator.requestedTimeToleranceAfter, .zero)
    }

    func testImportVideoUsesFortyFiveExactFrames() async throws {
        let videoURL = rootURL.appendingPathComponent("source.mp4")
        try Self.writeTestVideo(
            colors: (0..<45).map { index in
                NSColor(
                    calibratedHue: CGFloat(index) / 45,
                    saturation: 0.82,
                    brightness: 0.9,
                    alpha: 1
                )
            },
            frameRate: 15,
            size: CGSize(width: 64, height: 64),
            to: videoURL
        )

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)
        let result = try await importer.importCharacter(
            sourceURL: videoURL,
            name: "Video",
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: 0
        )

        XCTAssertEqual(result.sourceKind, .video)
        XCTAssertEqual(result.frameCount, 45)
        XCTAssertEqual(result.frameInterval, 1.0 / 15.0)
        XCTAssertEqual(try XCTUnwrap(result.videoStartTime), 0, accuracy: 0.001)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.framesURL(for: result.id).appendingPathComponent("frame-044.png").path))
    }

    func testEditExistingCharacterPreservesIdentityAndCreatedAt() async throws {
        let firstURL = rootURL.appendingPathComponent("first.png")
        let secondURL = rootURL.appendingPathComponent("second.png")
        try Self.writePNG(color: .systemBlue, size: CGSize(width: 120, height: 80), to: firstURL)
        try Self.writePNG(color: .systemRed, size: CGSize(width: 120, height: 80), to: secondURL)

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)
        let first = try await importer.importCharacter(
            sourceURL: firstURL,
            name: "First",
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: nil
        )

        let edited = try await importer.importCharacter(
            existingCharacter: first,
            sourceURL: secondURL,
            name: "Second",
            crop: CharacterCrop(scale: 1.5, offsetX: 0.2, offsetY: 0, shape: .roundedRectangle),
            videoStartTime: nil
        )

        XCTAssertEqual(edited.id, first.id)
        XCTAssertEqual(edited.createdAt, first.createdAt)
        XCTAssertEqual(edited.name, "Second")
        XCTAssertGreaterThanOrEqual(edited.updatedAt, first.updatedAt)
        XCTAssertEqual(try store.listCharacters().map(\.id), [first.id])
    }

    func testUnsupportedFileDoesNotCreatePackage() async throws {
        let sourceURL = rootURL.appendingPathComponent("source.txt")
        try Data("hello".utf8).write(to: sourceURL)

        let store = CustomCharacterStore(rootURL: rootURL.appendingPathComponent("characters", isDirectory: true))
        let importer = CustomCharacterImporter(store: store)

        do {
            _ = try await importer.importCharacter(
                sourceURL: sourceURL,
                name: "Text",
                crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
                videoStartTime: nil
            )
            XCTFail("Expected unsupported import to throw")
        } catch {
            XCTAssertTrue(try store.listCharacters().isEmpty)
        }
    }

    private static func writePNG(color: NSColor, size: CGSize, to url: URL) throws {
        let image = image(color: color, size: size)
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to create PNG fixture")
            return
        }
        try data.write(to: url)
    }

    private static func image(color: NSColor, size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }

    private static func alpha(at point: CGPoint, in image: NSImage) -> CGFloat {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            XCTFail("Failed to inspect rendered image")
            return 0
        }

        return bitmap.colorAt(x: Int(point.x), y: Int(point.y))?.alphaComponent ?? 0
    }

    private static func writeAnimatedGIF(colors: [NSColor], delay: TimeInterval, size: CGSize, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.gif.identifier as CFString,
            colors.count,
            nil
        ) else {
            XCTFail("Failed to create GIF destination")
            return
        }

        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delay
            ]
        ] as CFDictionary

        for color in colors {
            let image = NSImage(size: size)
            image.lockFocus()
            color.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            var rect = NSRect(origin: .zero, size: size)
            guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                XCTFail("Failed to create GIF frame")
                return
            }
            CGImageDestinationAddImage(destination, cgImage, frameProperties)
        }

        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private static func writeAnimatedPNG(colors: [NSColor], delay: TimeInterval, size: CGSize, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            colors.count,
            nil
        ) else {
            XCTFail("Failed to create APNG destination")
            return
        }

        let frameProperties = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyAPNGDelayTime: delay
            ]
        ] as CFDictionary

        for color in colors {
            let image = NSImage(size: size)
            image.lockFocus()
            color.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            var rect = NSRect(origin: .zero, size: size)
            guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                XCTFail("Failed to create APNG frame")
                return
            }
            CGImageDestinationAddImage(destination, cgImage, frameProperties)
        }

        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private static func writeTestVideo(colors: [NSColor], frameRate: Int32, size: CGSize, to url: URL) throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(size.width),
                AVVideoHeightKey: Int(size.height)
            ]
        )
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        for (index, color) in colors.enumerated() {
            while input.isReadyForMoreMediaData == false {
                Thread.sleep(forTimeInterval: 0.005)
            }
            guard let buffer = Self.pixelBuffer(color: color, size: size) else {
                XCTFail("Failed to create video pixel buffer")
                return
            }
            let time = CMTime(value: CMTimeValue(index), timescale: frameRate)
            XCTAssertTrue(adaptor.append(buffer, withPresentationTime: time))
        }

        input.markAsFinished()
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        if writer.status != .completed {
            throw writer.error ?? CocoaError(.fileWriteUnknown)
        }
    }

    private static func pixelBuffer(color: NSColor, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        context.setFillColor((color.usingColorSpace(.deviceRGB) ?? color).cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return pixelBuffer
    }
}
