import AppKit
import SwiftUI

struct ReminderCharacterFigureView: View {
    let palette: RestReminderPalette
    let size: CGFloat
    let selection: ReminderCharacterSelection
    let isActive: Bool

    @ObservedObject private var settings = Settings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch selection {
        case .builtIn(let style):
            BuiltInReminderCharacterFigure(
                palette: palette,
                size: size,
                style: style,
                isActive: isActive
            )
        case .custom(let id):
            CustomReminderCharacterFigure(
                id: id,
                palette: palette,
                size: size,
                isActive: isActive && !reduceMotion,
                resourceVersion: settings.customCharacterResourceVersion
            )
        }
    }
}

private struct CustomReminderCharacterFigure: View {
    let id: UUID
    let palette: RestReminderPalette
    let size: CGFloat
    let isActive: Bool
    let resourceVersion: UUID

    @State private var frameIndex = 0
    @State private var package: FramePackage?
    @State private var frameTaskID = UUID()

    private let store = CustomCharacterStore()

    var body: some View {
        Group {
            if let image = currentImage {
                ZStack(alignment: .bottom) {
                    Capsule(style: .continuous)
                        .fill(palette.figureGround)
                        .frame(width: size * 0.62, height: size * 0.05)
                        .offset(y: size * 0.02)

                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.88, height: size * 0.88)
                        .accessibilityHidden(true)
                }
                .frame(width: size, height: size)
            } else {
                BuiltInReminderCharacterFigure(
                    palette: palette,
                    size: size,
                    style: .line,
                    isActive: isActive
                )
            }
        }
        .task(id: id) {
            loadPackage()
        }
        .onChange(of: resourceVersion) { _, _ in loadPackage() }
        .onChange(of: isActive) { _, _ in restartAnimation() }
        .task(id: frameTaskID) {
            await runFrameAnimation()
        }
    }

    private var currentImage: NSImage? {
        guard let package else { return nil }
        if isActive, package.frames.isEmpty == false {
            return package.frames[min(frameIndex, package.frames.count - 1)]
        }
        return package.preview
    }

    private func loadPackage() {
        package = FramePackage.load(id: id, store: store)
        frameIndex = 0
        frameTaskID = UUID()
    }

    private func restartAnimation() {
        frameIndex = 0
        frameTaskID = UUID()
    }

    private func runFrameAnimation() async {
        guard isActive, let package, package.frames.count > 1 else { return }
        while Task.isCancelled == false {
            try? await Task.sleep(nanoseconds: UInt64(package.frameInterval * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                frameIndex = (frameIndex + 1) % package.frames.count
            }
        }
    }

    private struct FramePackage {
        let preview: NSImage
        let frames: [NSImage]
        let frameInterval: TimeInterval

        static func load(id: UUID, store: CustomCharacterStore) -> FramePackage? {
            guard let manifest = try? store.loadManifest(id: id) else { return nil }
            let frames = (0..<manifest.frameCount).compactMap { index in
                NSImage(contentsOf: store.framesURL(for: id).appendingPathComponent(String(format: "frame-%03d.png", index)))
            }
            let preview = NSImage(contentsOf: store.previewURL(for: id)) ?? frames.first
            guard let preview else { return nil }
            return FramePackage(
                preview: preview,
                frames: frames,
                frameInterval: Self.safeFrameInterval(manifest.frameInterval)
            )
        }

        private static func safeFrameInterval(_ interval: TimeInterval) -> TimeInterval {
            guard interval.isFinite else { return 1.0 / 15.0 }
            return min(10, max(1.0 / 60.0, interval))
        }
    }
}
