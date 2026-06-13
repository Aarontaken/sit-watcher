import AppKit
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
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to create PNG fixture")
            return
        }
        try data.write(to: url)
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
}
