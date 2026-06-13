import XCTest
@testable import SitWatcher

final class ReminderCharacterSelectionTests: XCTestCase {
    func testBuiltInSelectionCodableRoundTrip() throws {
        let selection = ReminderCharacterSelection.builtIn(.pixelJump)
        let data = try JSONEncoder().encode(selection)
        let decoded = try JSONDecoder().decode(ReminderCharacterSelection.self, from: data)
        XCTAssertEqual(decoded, selection)
    }

    func testCustomSelectionCodableRoundTrip() throws {
        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let selection = ReminderCharacterSelection.custom(id)
        let data = try JSONEncoder().encode(selection)
        let decoded = try JSONDecoder().decode(ReminderCharacterSelection.self, from: data)
        XCTAssertEqual(decoded, selection)
    }

    func testBuiltInSelectionDefaultsToLineWhenRawValueIsInvalid() {
        XCTAssertEqual(ReminderCharacterSelection.fromStoredString("builtIn:not-real"), .builtIn(.line))
    }

    func testCustomSelectionDefaultsToLineWhenUUIDIsInvalid() {
        XCTAssertEqual(ReminderCharacterSelection.fromStoredString("custom:not-a-uuid"), .builtIn(.line))
    }

    func testMalformedStoredStringDefaultsToLine() {
        XCTAssertEqual(ReminderCharacterSelection.fromStoredString("not-useful"), .builtIn(.line))
    }

    func testInvalidCustomCodableValueDefaultsToLine() throws {
        let data = #"{"kind":"custom","value":"not-a-uuid"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ReminderCharacterSelection.self, from: data)
        XCTAssertEqual(decoded, .builtIn(.line))
    }

    func testInvalidBuiltInCodableValueDefaultsToLine() throws {
        let data = #"{"kind":"builtIn","value":"not-real"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ReminderCharacterSelection.self, from: data)
        XCTAssertEqual(decoded, .builtIn(.line))
    }
}
