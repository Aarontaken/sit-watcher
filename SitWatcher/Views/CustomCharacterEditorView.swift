import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct CustomCharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let existingCharacter: CustomReminderCharacter?
    var onComplete: (Result<CustomReminderCharacter, Error>) -> Void

    @State private var name: String
    @State private var crop: CharacterCrop
    @State private var selectedURL: URL?
    @State private var videoStartTime: TimeInterval
    @State private var isImporting = false
    @State private var isImporterPresented = false
    @State private var dragStartOffset: CGSize?

    init(
        existingCharacter: CustomReminderCharacter?,
        onComplete: @escaping (Result<CustomReminderCharacter, Error>) -> Void
    ) {
        self.existingCharacter = existingCharacter
        self.onComplete = onComplete
        _name = State(initialValue: existingCharacter?.name ?? "")
        _crop = State(
            initialValue: existingCharacter?.crop ?? CharacterCrop(
                scale: 1,
                offsetX: 0,
                offsetY: 0,
                shape: .circle
            )
        )
        _selectedURL = State(
            initialValue: existingCharacter.map {
                CustomCharacterStore().sourceURL(for: $0)
            }
        )
        _videoStartTime = State(initialValue: existingCharacter?.videoStartTime ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(existingCharacter == nil ? "Import Character" : "Edit Character")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                if isImporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            previewStage

            VStack(alignment: .leading, spacing: 10) {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Picker("Crop", selection: $crop.shape) {
                    ForEach(CustomCharacterCropShape.allCases) { shape in
                        Text(shape.caption).tag(shape)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Zoom")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Slider(value: $crop.scale, in: 1...4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Start")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Slider(value: $videoStartTime, in: 0...60)
                }
            }

            HStack(spacing: 10) {
                Button {
                    isImporterPresented = true
                } label: {
                    Label("Choose File", systemImage: "folder")
                }

                Spacer()

                Button("Cancel", role: .cancel) {
                    dismiss()
                }

                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedURL == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
            }
        }
        .padding(22)
        .frame(width: 360)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.image, .movie, .gif]
        ) { result in
            if case .success(let url) = result {
                selectedURL = url
            }
        }
    }

    private var previewStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))

            previewContent
                .frame(width: 160, height: 160)
                .scaleEffect(crop.scale)
                .offset(x: crop.offsetX * 52, y: crop.offsetY * 52)
                .clipShape(previewClipShape)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .frame(width: 316, height: 220)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if dragStartOffset == nil {
                        dragStartOffset = CGSize(width: crop.offsetX, height: crop.offsetY)
                    }
                    let start = dragStartOffset ?? .zero
                    crop.offsetX = clamp(start.width + gesture.translation.width / 180)
                    crop.offsetY = clamp(start.height + gesture.translation.height / 180)
                }
                .onEnded { _ in
                    dragStartOffset = nil
                }
        )
    }

    @ViewBuilder
    private var previewContent: some View {
        if let selectedURL, let image = NSImage(contentsOf: selectedURL) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var previewClipShape: AnyShape {
        switch crop.shape {
        case .circle:
            return AnyShape(Circle())
        case .roundedRectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        case .square:
            return AnyShape(Rectangle())
        }
    }

    private func save() {
        guard let selectedURL else { return }
        isImporting = true

        Task {
            do {
                let character = try await CustomCharacterImporter().importCharacter(
                    existingCharacter: existingCharacter,
                    sourceURL: selectedURL,
                    name: name,
                    crop: crop,
                    videoStartTime: videoStartTime
                )
                await MainActor.run {
                    onComplete(.success(character))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    onComplete(.failure(error))
                    dismiss()
                }
            }
        }
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, -1), 1)
    }
}

private extension CustomCharacterCropShape {
    var caption: String {
        switch self {
        case .circle:
            return "Circle"
        case .roundedRectangle:
            return "Rounded"
        case .square:
            return "Square"
        }
    }
}
