import Foundation

enum ReminderCharacterSelection: Equatable, Codable {
    case builtIn(RestReminderFigureStyle)
    case custom(UUID)

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    private enum Kind: String, Codable {
        case builtIn
        case custom
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let value = try container.decode(String.self, forKey: .value)
        switch kind {
        case .builtIn:
            self = .builtIn(RestReminderFigureStyle(rawValue: value) ?? .line)
        case .custom:
            if let id = UUID(uuidString: value) {
                self = .custom(id)
            } else {
                self = .builtIn(.line)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .builtIn(let style):
            try container.encode(Kind.builtIn, forKey: .kind)
            try container.encode(style.rawValue, forKey: .value)
        case .custom(let id):
            try container.encode(Kind.custom, forKey: .kind)
            try container.encode(id.uuidString, forKey: .value)
        }
    }

    var storedString: String {
        switch self {
        case .builtIn(let style):
            return "builtIn:\(style.rawValue)"
        case .custom(let id):
            return "custom:\(id.uuidString)"
        }
    }

    static func fromStoredString(_ stored: String?) -> ReminderCharacterSelection {
        guard let stored else { return .builtIn(.line) }
        if stored.hasPrefix("builtIn:") {
            let raw = String(stored.dropFirst("builtIn:".count))
            return .builtIn(RestReminderFigureStyle(rawValue: raw) ?? .line)
        }
        if stored.hasPrefix("custom:") {
            let raw = String(stored.dropFirst("custom:".count))
            if let id = UUID(uuidString: raw) {
                return .custom(id)
            }
        }
        return .builtIn(.line)
    }
}
