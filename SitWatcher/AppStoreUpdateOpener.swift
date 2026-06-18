import AppKit
import Foundation

struct AppStoreUpdateOpener {
    static let configuredAppID = ""

    private let appID: String
    private let searchTerm: String

    init(appID: String = Self.configuredAppID, searchTerm: String = "SitWatcher") {
        self.appID = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchTerm = searchTerm
    }

    func urlsToOpen() -> [URL] {
        if appID.isEmpty {
            return [
                URL(string: "https://apps.apple.com/search?term=\(Self.percentEncoded(searchTerm))")!
            ]
        }

        return [
            URL(string: "macappstore://apps.apple.com/app/id\(appID)")!,
            URL(string: "https://apps.apple.com/app/id\(appID)")!,
        ]
    }

    @discardableResult
    func open(using openURL: (URL) -> Bool = { NSWorkspace.shared.open($0) }) -> Bool {
        for url in urlsToOpen() {
            if openURL(url) {
                return true
            }
        }

        print("Failed to open App Store URL candidates: \(urlsToOpen().map(\.absoluteString))")
        return false
    }

    private static func percentEncoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
