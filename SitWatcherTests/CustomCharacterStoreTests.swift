import XCTest
@testable import SitWatcher

final class CustomCharacterStoreTests: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SitWatcherCustomCharacterStoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testSaveAndListManifest() throws {
        let store = CustomCharacterStore(rootURL: rootURL)
        let id = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
        let character = makeCharacter(
            id: id,
            name: "Desk Cat",
            sourceFilename: "source.png",
            createdAt: Date(timeIntervalSince1970: 10.123)
        )

        try store.saveManifest(character)

        XCTAssertEqual(try store.listCharacters().map(\.id), [id])
        XCTAssertEqual(try store.loadManifest(id: id).name, "Desk Cat")
        XCTAssertEqual(try store.loadManifest(id: id).createdAt.timeIntervalSince1970, 10.123, accuracy: 0.001)
        XCTAssertEqual(store.sourceURL(for: character).lastPathComponent, "source.png")
    }

    func testSaveManifestCreatesMissingRootDirectory() throws {
        let missingRoot = rootURL.appendingPathComponent("missing-root", isDirectory: true)
        let store = CustomCharacterStore(rootURL: missingRoot)
        let character = makeCharacter(id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!)

        try store.saveManifest(character)

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.manifestURL(for: character.id).path))
    }

    func testSaveManifestRejectsSourceFilenameTraversal() throws {
        let store = CustomCharacterStore(rootURL: rootURL)
        let character = makeCharacter(
            id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
            sourceFilename: "../source.png"
        )

        XCTAssertThrowsError(try store.saveManifest(character))
    }

    func testListCharactersSkipsCorruptManifest() throws {
        let store = CustomCharacterStore(rootURL: rootURL)
        let validID = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
        try store.saveManifest(makeCharacter(id: validID, name: "Valid"))

        let corruptID = UUID(uuidString: "bbbbbbbb-cccc-dddd-eeee-ffffffffffff")!
        let corruptPackage = store.packageURL(for: corruptID)
        try FileManager.default.createDirectory(at: corruptPackage, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: corruptPackage.appendingPathComponent("manifest.json"))

        XCTAssertEqual(try store.listCharacters().map(\.id), [validID])
    }

    func testDeleteCurrentCustomSelectionFallsBackToLine() throws {
        let id = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
        let newSelection = CustomCharacterStore.selectionAfterDeleting(id: id, current: .custom(id))
        XCTAssertEqual(newSelection, .builtIn(.line))
    }

    func testDeleteOtherCustomSelectionKeepsCurrentSelection() throws {
        let deleted = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
        let current = ReminderCharacterSelection.custom(UUID(uuidString: "11111111-2222-3333-4444-555555555555")!)
        XCTAssertEqual(CustomCharacterStore.selectionAfterDeleting(id: deleted, current: current), current)
    }

    private func makeCharacter(
        id: UUID,
        name: String = "Desk Cat",
        sourceFilename: String = "source.png",
        createdAt: Date = Date(timeIntervalSince1970: 10)
    ) -> CustomReminderCharacter {
        CustomReminderCharacter(
            id: id,
            name: name,
            sourceKind: .stillImage,
            sourceFilename: sourceFilename,
            createdAt: createdAt,
            updatedAt: createdAt,
            frameCount: 1,
            frameInterval: 1,
            crop: CharacterCrop(scale: 1.2, offsetX: 0.1, offsetY: -0.2, shape: .circle),
            videoStartTime: nil
        )
    }
}
