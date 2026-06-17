import AppKit
import AVFoundation
import SwiftUI
import XCTest
@testable import SitWatcher

@MainActor
final class CustomCharacterEditorWindowControllerTests: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SitWatcherCustomCharacterEditorWindowControllerTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
        rootURL = nil
        try super.tearDownWithError()
    }

    func testEditorPanelIsIndependentCenteredAndStaysVisibleWhenAppDeactivates() {
        let controller = CustomCharacterEditorWindowController()
        let panel = controller.makePanelForTesting(existingCharacter: nil, language: .simplifiedChinese) { _ in }

        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertFalse(panel.hidesOnDeactivate)
        XCTAssertEqual(panel.level, .modalPanel)
        if #available(macOS 15.0, *) {
            XCTAssertTrue(panel.isMovableByWindowBackground)
        } else {
            XCTAssertFalse(panel.isMovableByWindowBackground)
        }
        XCTAssertEqual(panel.contentMinSize, NSSize(width: 680, height: 540))
        XCTAssertEqual(panel.contentMaxSize, NSSize(width: 680, height: 540))
    }

    func testEditorPanelReceivesSelectedLanguage() {
        let controller = CustomCharacterEditorWindowController()
        let panel = controller.makePanelForTesting(existingCharacter: nil, language: .simplifiedChinese) { _ in }

        let hostingView = try? XCTUnwrap(panel.contentView as? NSHostingView<CustomCharacterEditorView>)
        XCTAssertEqual(hostingView?.rootView.language, .simplifiedChinese)
    }

    func testExistingVideoCharacterUsesVideoFrameForInitialPreview() async throws {
        let store = CustomCharacterStore(rootURL: rootURL)
        let sourceURL = rootURL.appendingPathComponent("source.mp4")
        try Self.writeTestVideo(colors: [.systemBlue, .systemGreen, .systemOrange], frameRate: 3, size: CGSize(width: 64, height: 64), to: sourceURL)
        let character = CustomReminderCharacter(
            id: UUID(),
            name: "Video Role",
            sourceKind: .video,
            sourceFilename: "source.mp4",
            createdAt: Date(),
            updatedAt: Date(),
            frameCount: 45,
            frameInterval: 1.0 / 15.0,
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: 0
        )
        try FileManager.default.createDirectory(at: store.packageURL(for: character.id), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: sourceURL, to: store.sourceURL(for: character))

        let preview = try await CustomCharacterEditorView.initialPreviewImage(for: character, store: store)

        XCTAssertGreaterThan(preview.size.width, 0)
        XCTAssertGreaterThan(preview.size.height, 0)
    }

    func testShowReplacesExistingEditorPanelContent() {
        let first = CustomReminderCharacter(
            id: UUID(),
            name: "First",
            sourceKind: .stillImage,
            sourceFilename: "first.png",
            createdAt: Date(),
            updatedAt: Date(),
            frameCount: 1,
            frameInterval: 0,
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .circle),
            videoStartTime: nil
        )
        let second = CustomReminderCharacter(
            id: UUID(),
            name: "Second",
            sourceKind: .stillImage,
            sourceFilename: "second.png",
            createdAt: Date(),
            updatedAt: Date(),
            frameCount: 1,
            frameInterval: 0,
            crop: CharacterCrop(scale: 1, offsetX: 0, offsetY: 0, shape: .square),
            videoStartTime: nil
        )
        let controller = CustomCharacterEditorWindowController()

        controller.show(existingCharacter: first, language: .simplifiedChinese) { _ in }
        controller.show(existingCharacter: second, language: .simplifiedChinese) { _ in }

        let panel = try? XCTUnwrap(controller.currentPanelForTesting)
        let hostingView = try? XCTUnwrap(panel?.contentView as? NSHostingView<CustomCharacterEditorView>)
        XCTAssertEqual(hostingView?.rootView.existingCharacter?.id, second.id)
        controller.close()
    }

    func testDeleteConfirmationPanelIsIndependentCenteredAndStaysVisibleWhenAppDeactivates() {
        let controller = CustomCharacterDeleteConfirmationWindowController()
        let panel = controller.makePanelForTesting(
            characterName: "Stretch Cat",
            language: .simplifiedChinese,
            onConfirm: {},
            onCancel: {}
        )

        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertFalse(panel.hidesOnDeactivate)
        XCTAssertEqual(panel.level, .modalPanel)
        XCTAssertEqual(panel.contentMinSize, NSSize(width: 420, height: 220))
        XCTAssertEqual(panel.contentMaxSize, NSSize(width: 420, height: 220))
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
