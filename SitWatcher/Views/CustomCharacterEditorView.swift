import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

struct CustomCharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let allowedTypes: [UTType] = [
        .png,
        .jpeg,
        .heic,
        .gif,
        UTType(filenameExtension: "apng") ?? .png,
        .webP,
        .quickTimeMovie,
        .mpeg4Movie,
        UTType(filenameExtension: "m4v") ?? .movie
    ]

    let existingCharacter: CustomReminderCharacter?
    let language: UIAppLanguage
    var onComplete: (Result<CustomReminderCharacter, Error>) -> Void
    var onDismiss: (() -> Void)?

    @State private var name: String
    @State private var crop: CharacterCrop
    @State private var selectedURL: URL?
    @State private var videoStartTime: TimeInterval
    @State private var isImporting = false
    @State private var isImporterPresented = false
    @State private var dragStartOffset: CGSize?
    @State private var previewImage: NSImage?
    private let zoomRange: ClosedRange<CGFloat> = 0.5...4
    private let videoStartRange: ClosedRange<Double> = 0...60

    init(
        existingCharacter: CustomReminderCharacter?,
        language: UIAppLanguage = .system,
        onComplete: @escaping (Result<CustomReminderCharacter, Error>) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.existingCharacter = existingCharacter
        self.language = language
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        _name = State(initialValue: existingCharacter?.name ?? Self.localized(language: language, chinese: "自定义角色", english: "Custom Character"))
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
        ZStack {
            editorBackdrop

            VStack(spacing: 0) {
                editorHeader

                HStack(spacing: 0) {
                    previewColumn
                        .frame(width: 330)

                    Divider()
                        .overlay(Color.black.opacity(0.08))

                    controlsColumn
                        .frame(maxWidth: .infinity)
                }

                editorFooter
            }
        }
        .frame(width: 680, height: 540)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: allowedTypes
        ) { result in
            if case .success(let url) = result {
                selectedURL = url
                loadPreviewImage(from: url, updateDefaultCrop: existingCharacter == nil)
            }
        }
        .interactiveDismissDisabled(isImporting)
        .task(id: existingCharacter?.id) {
            guard let existingCharacter else { return }
            await loadInitialPreviewImage(for: existingCharacter)
        }
        .onChange(of: videoStartTime) { _, _ in
            guard let selectedURL, isVideoURL(selectedURL) else { return }
            loadPreviewImage(from: selectedURL, updateDefaultCrop: false)
        }
    }

    private var showsVideoStart: Bool {
        guard let selectedURL else { return false }
        return isVideoURL(selectedURL)
    }

    private var editorBackdrop: some View {
        ZStack {
            Color(red: 0.93, green: 0.91, blue: 0.86)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.58),
                    Color(red: 0.74, green: 0.83, blue: 0.76).opacity(0.22),
                    Color(red: 0.88, green: 0.72, blue: 0.44).opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .fill(
                    ImagePaint(
                        image: Image(systemName: "circle.grid.cross"),
                        scale: 42
                    )
                )
                .opacity(0.018)
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.14, green: 0.16, blue: 0.15))

                Image(systemName: "figure.wave")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(red: 0.91, green: 0.74, blue: 0.39))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(existingCharacter == nil ? text(chinese: "角色工作台", english: "Character Studio") : text(chinese: "编辑角色", english: "Edit Character"))
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.14, green: 0.15, blue: 0.13))

                Text(text(chinese: "调整提醒角色在屏幕上的显示方式。", english: "Shape how your reminder appears on screen."))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.52))
            }

            Spacer()

            if isImporting {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color(red: 0.34, green: 0.48, blue: 0.39))
            }

            Button {
                closeEditor()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.62))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.46)))
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isImporting)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var previewColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            previewStage

            HStack(spacing: 8) {
                Label(sourceCaption, systemImage: sourceIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.56))

                Spacer()

                Text(crop.shape.caption(language: language))
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.white.opacity(0.88))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.42)))
            }
            .padding(.horizontal, 8)

            Text(text(chinese: "拖动预览来摆放角色。用缩放和形状控制最终提醒裁剪。", english: "Drag the preview to place the character. Use zoom and shape controls for the final reminder crop."))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.48))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
        .padding(.leading, 28)
        .padding(.trailing, 22)
        .padding(.bottom, 20)
    }

    private var controlsColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            editorField(text(chinese: "名称", english: "Name")) {
                TextField(text(chinese: "桌面伙伴", english: "Desk buddy"), text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(controlBackground)
            }

            editorField(text(chinese: "裁剪形状", english: "Crop Shape")) {
                Picker("Crop", selection: $crop.shape) {
                    ForEach(CustomCharacterCropShape.allCases) { shape in
                        Label(shape.caption(language: language), systemImage: shape.iconName).tag(shape)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            editorField(text(chinese: "缩放", english: "Zoom")) {
                HStack(spacing: 12) {
                    stepButton(systemImage: "minus.magnifyingglass", accessibilityLabel: text(chinese: "缩小", english: "Zoom out")) {
                        adjustZoom(by: -0.1)
                    }

                    Slider(value: $crop.scale, in: zoomRange)
                        .tint(Color(red: 0.37, green: 0.52, blue: 0.42))

                    Text(String(format: "%.1fx", crop.scale))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.black.opacity(0.58))
                        .frame(width: 38, alignment: .trailing)

                    stepButton(systemImage: "plus.magnifyingglass", accessibilityLabel: text(chinese: "放大", english: "Zoom in")) {
                        adjustZoom(by: 0.1)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(controlBackground)
            }

            if showsVideoStart {
                editorField(text(chinese: "视频起点", english: "Video Start")) {
                    HStack(spacing: 12) {
                        stepButton(systemImage: "backward.end", accessibilityLabel: text(chinese: "视频起点后退 1 秒", english: "Move video start back 1 second")) {
                            adjustVideoStart(by: -1)
                        }

                        Slider(value: $videoStartTime, in: videoStartRange)
                            .tint(Color(red: 0.37, green: 0.52, blue: 0.42))

                        Text("\(Int(videoStartTime))s")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.black.opacity(0.58))
                            .frame(width: 34, alignment: .trailing)

                        stepButton(systemImage: "forward.end", accessibilityLabel: text(chinese: "视频起点前进 1 秒", english: "Move video start forward 1 second")) {
                            adjustVideoStart(by: 1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(controlBackground)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 2)
        .padding(.bottom, 18)
    }

    private var editorFooter: some View {
        HStack(spacing: 12) {
            Button {
                isImporterPresented = true
            } label: {
                Label(text(chinese: "选择文件", english: "Choose File"), systemImage: "folder.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(height: 38)
                    .padding(.horizontal, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.15, green: 0.17, blue: 0.15))
            .background(controlBackground)

            Spacer()

            Button(text(chinese: "取消", english: "Cancel"), role: .cancel) {
                closeEditor()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.58))
            .frame(height: 38)
            .padding(.horizontal, 14)
            .disabled(isImporting)

            Button {
                save()
            } label: {
                Label(text(chinese: "保存角色", english: "Save Character"), systemImage: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .frame(height: 38)
                    .padding(.horizontal, 16)
                    .contentShape(Capsule(style: .continuous))
                    .background {
                        Capsule(style: .continuous)
                            .fill(saveButtonFill)
                            .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)
                    }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .keyboardShortcut(.defaultAction)
            .disabled(saveDisabled)
            .opacity(saveDisabled ? 0.48 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.34))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func editorField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.45))

            content()
        }
    }

    private var controlBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.58))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            }
    }

    private var saveButtonFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.22, blue: 0.19),
                Color(red: 0.37, green: 0.52, blue: 0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func stepButton(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.5))
                .frame(width: 24, height: 24)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(Circle().fill(Color.white.opacity(0.42)))
        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
        .accessibilityLabel(accessibilityLabel)
    }

    private var previewFrame: some View {
        Group {
            switch crop.shape {
            case .none:
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    .foregroundStyle(Color.white.opacity(0.68))
            case .circle:
                Circle().strokeBorder(Color.white.opacity(0.72), lineWidth: 2)
            case .roundedRectangle:
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.72), lineWidth: 2)
            case .square:
                Rectangle().strokeBorder(Color.white.opacity(0.72), lineWidth: 2)
            }
        }
        .frame(width: 188, height: 188)
    }

    private var sourceCaption: String {
        guard let selectedURL else { return text(chinese: "未选择来源", english: "No source selected") }
        let filename = selectedURL.lastPathComponent
        return filename.isEmpty ? text(chinese: "已选择来源", english: "Source selected") : filename
    }

    private var sourceIcon: String {
        guard let selectedURL else { return "photo.badge.plus" }
        return isVideoURL(selectedURL) ? "video" : "photo"
    }

    private var saveDisabled: Bool {
        selectedURL == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting
    }

    private var previewStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.16, blue: 0.16),
                            Color(red: 0.07, green: 0.075, blue: 0.078)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color(red: 0.88, green: 0.73, blue: 0.43).opacity(0.24))
                        .frame(width: 150, height: 150)
                        .blur(radius: 28)
                        .offset(x: -34, y: -46)
                }
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(red: 0.45, green: 0.66, blue: 0.56).opacity(0.22))
                        .frame(width: 130, height: 130)
                        .blur(radius: 24)
                        .offset(x: 32, y: 34)
                }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
                .padding(13)

            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.28))
                .frame(width: 154, height: 16)
                .blur(radius: 1)
                .offset(y: 93)

            previewContent
                .frame(width: 188, height: 188)
                .scaleEffect(crop.scale)
                .offset(x: crop.offsetX * 62, y: crop.offsetY * 62)
                .mask {
                    previewMask
                        .frame(width: 188, height: 188)
                }

            previewFrame
        }
        .frame(width: 258, height: 258)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if dragStartOffset == nil {
                        dragStartOffset = CGSize(width: crop.offsetX, height: crop.offsetY)
                    }
                    let start = dragStartOffset ?? .zero
                    crop.offsetX = clampedOffset(start.width + gesture.translation.width / 180)
                    crop.offsetY = clampedOffset(start.height + gesture.translation.height / 180)
                }
                .onEnded { _ in
                    dragStartOffset = nil
                }
        )
    }

    @ViewBuilder
    private var previewContent: some View {
        if let image = previewImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 44, weight: .semibold))
                Text(text(chinese: "放入一个角色", english: "Drop in a character"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.white.opacity(0.72))
        }
    }

    @ViewBuilder
    private var previewMask: some View {
        switch crop.shape {
        case .none:
            Rectangle()
        case .circle:
            Circle()
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: 28, style: .continuous)
        case .square:
            Rectangle()
        }
    }

    private func save() {
        guard let selectedURL else { return }
        isImporting = true

        Task {
            do {
                let didAccessSecurityScopedResource = selectedURL.startAccessingSecurityScopedResource()
                defer {
                    if didAccessSecurityScopedResource {
                        selectedURL.stopAccessingSecurityScopedResource()
                    }
                }
                let character = try await CustomCharacterImporter().importCharacter(
                    existingCharacter: existingCharacter,
                    sourceURL: selectedURL,
                    name: name,
                    crop: crop,
                    videoStartTime: videoStartTime
                )
                await MainActor.run {
                    onComplete(.success(character))
                    closeEditor()
                }
            } catch {
                await MainActor.run {
                    onComplete(.failure(error))
                    closeEditor()
                }
            }
        }
    }

    private func closeEditor() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func loadPreviewImage(from url: URL, updateDefaultCrop: Bool) {
        let expectedURL = url
        Task {
            let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
            defer {
                if didAccessSecurityScopedResource {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let loadedImage = try? await CustomCharacterMediaPreviewer.previewImage(from: url, startTime: videoStartTime)
            let hasTransparency = updateDefaultCrop ? imageHasTransparency(at: url) : false
            await MainActor.run {
                guard selectedURL == expectedURL else { return }
                previewImage = loadedImage
                if updateDefaultCrop {
                    crop.shape = hasTransparency ? .none : .circle
                }
            }
        }
    }

    private func loadInitialPreviewImage(for character: CustomReminderCharacter) async {
        let store = CustomCharacterStore()
        guard let loadedImage = try? await Self.initialPreviewImage(for: character, store: store) else { return }
        previewImage = loadedImage
    }

    static func initialPreviewImage(for character: CustomReminderCharacter, store: CustomCharacterStore = CustomCharacterStore()) async throws -> NSImage {
        try await CustomCharacterMediaPreviewer.previewImage(
            from: store.sourceURL(for: character),
            startTime: character.videoStartTime ?? 0
        )
    }

    private func imageHasTransparency(at url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let hasAlpha = properties[kCGImagePropertyHasAlpha] as? Bool else {
            return false
        }
        return hasAlpha
    }

    private func clampedOffset(_ value: CGFloat) -> CGFloat {
        let maxOffset = max(0, crop.scale - 1)
        return min(max(value, -maxOffset), maxOffset)
    }

    private func adjustZoom(by delta: CGFloat) {
        crop.scale = min(max(crop.scale + delta, zoomRange.lowerBound), zoomRange.upperBound)
        crop.offsetX = clampedOffset(crop.offsetX)
        crop.offsetY = clampedOffset(crop.offsetY)
    }

    private func adjustVideoStart(by delta: Double) {
        videoStartTime = min(max(videoStartTime + delta, videoStartRange.lowerBound), videoStartRange.upperBound)
    }

    private func isVideoURL(_ url: URL) -> Bool {
        ["mov", "mp4", "m4v"].contains(url.pathExtension.lowercased())
    }

    private func text(chinese: String, english: String) -> String {
        Self.localized(language: language, chinese: chinese, english: english)
    }

    fileprivate static func localized(language: UIAppLanguage, chinese: String, english: String) -> String {
        switch language {
        case .english:
            return english
        case .simplifiedChinese:
            return chinese
        case .system:
            return Locale.autoupdatingCurrent.language.languageCode?.identifier == "zh" ? chinese : english
        }
    }
}

private extension CustomCharacterCropShape {
    func caption(language: UIAppLanguage) -> String {
        switch self {
        case .none:
            return CustomCharacterEditorView.localized(language: language, chinese: "无", english: "None")
        case .circle:
            return CustomCharacterEditorView.localized(language: language, chinese: "圆形", english: "Circle")
        case .roundedRectangle:
            return CustomCharacterEditorView.localized(language: language, chinese: "圆角", english: "Rounded")
        case .square:
            return CustomCharacterEditorView.localized(language: language, chinese: "方形", english: "Square")
        }
    }

    var iconName: String {
        switch self {
        case .none:
            return "square.dashed"
        case .circle:
            return "circle"
        case .roundedRectangle:
            return "rectangle"
        case .square:
            return "square"
        }
    }
}
