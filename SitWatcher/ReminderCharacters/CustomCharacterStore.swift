import Foundation

struct CustomCharacterStore {
    let rootURL: URL
    private let fileManager: FileManager

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.rootURL = support.appendingPathComponent("SitWatcher", isDirectory: true)
                .appendingPathComponent("CustomCharacters", isDirectory: true)
        }
    }

    func packageURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    func framesURL(for id: UUID) -> URL {
        packageURL(for: id).appendingPathComponent("frames", isDirectory: true)
    }

    func previewURL(for id: UUID) -> URL {
        packageURL(for: id).appendingPathComponent("preview.png")
    }

    func sourceURL(for character: CustomReminderCharacter) -> URL {
        packageURL(for: character.id).appendingPathComponent(sanitizedSourceFilename(character.sourceFilename))
    }

    func manifestURL(for id: UUID) -> URL {
        packageURL(for: id).appendingPathComponent("manifest.json")
    }

    func saveManifest(_ character: CustomReminderCharacter) throws {
        try fileManager.createDirectory(at: packageURL(for: character.id), withIntermediateDirectories: true)
        try validateSourceFilename(character.sourceFilename)
        let data = try JSONEncoder.customCharacterEncoder.encode(character)
        try data.write(to: manifestURL(for: character.id), options: .atomic)
    }

    func loadManifest(id: UUID) throws -> CustomReminderCharacter {
        let data = try Data(contentsOf: manifestURL(for: id))
        return try JSONDecoder.customCharacterDecoder.decode(CustomReminderCharacter.self, from: data)
    }

    func listCharacters() throws -> [CustomReminderCharacter] {
        guard fileManager.fileExists(atPath: rootURL.path) else { return [] }
        let packageURLs = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
        return packageURLs.compactMap { url in
            let manifestURL = url.appendingPathComponent("manifest.json")
            guard fileManager.fileExists(atPath: manifestURL.path) else { return nil }
            do {
                let data = try Data(contentsOf: manifestURL)
                return try JSONDecoder.customCharacterDecoder.decode(CustomReminderCharacter.self, from: data)
            } catch {
                print("Failed to load custom character manifest at \(manifestURL.path): \(error)")
                return nil
            }
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    func deleteCharacter(id: UUID) throws {
        let url = packageURL(for: id)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    static func selectionAfterDeleting(id: UUID, current: ReminderCharacterSelection) -> ReminderCharacterSelection {
        current == .custom(id) ? .builtIn(.line) : current
    }

    private func validateSourceFilename(_ filename: String) throws {
        let basename = sanitizedSourceFilename(filename)
        guard filename.isEmpty == false, filename == basename else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
    }

    private func sanitizedSourceFilename(_ filename: String) -> String {
        URL(fileURLWithPath: filename).lastPathComponent
    }
}

private extension JSONEncoder {
    static var customCharacterEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .customCharacterISO8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var customCharacterDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customCharacterISO8601
        return decoder
    }
}

private extension JSONEncoder.DateEncodingStrategy {
    static let customCharacterISO8601 = JSONEncoder.DateEncodingStrategy.custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(CustomCharacterDateFormatter.shared.string(from: date))
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    static let customCharacterISO8601 = JSONDecoder.DateDecodingStrategy.custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = CustomCharacterDateFormatter.shared.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid custom character date: \(string)"
        )
    }
}

private enum CustomCharacterDateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
