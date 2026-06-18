import XCTest
@testable import SitWatcher

final class AppStoreUpdateOpenerTests: XCTestCase {
    func testURLsUseMacAppStoreThenHTTPSWhenAppIDIsConfigured() {
        let opener = AppStoreUpdateOpener(appID: "1234567890")

        XCTAssertEqual(opener.urlsToOpen().map(\.absoluteString), [
            "macappstore://apps.apple.com/app/id1234567890",
            "https://apps.apple.com/app/id1234567890",
        ])
    }

    func testURLsUseSearchFallbackWhenAppIDIsEmpty() {
        let opener = AppStoreUpdateOpener(appID: "")

        XCTAssertEqual(opener.urlsToOpen().map(\.absoluteString), [
            "https://apps.apple.com/search?term=SitWatcher",
        ])
    }

    func testOpenTriesHTTPSWhenMacAppStoreURLFails() {
        let opener = AppStoreUpdateOpener(appID: "1234567890")
        var opened: [String] = []

        let didOpen = opener.open { url in
            opened.append(url.absoluteString)
            return url.scheme == "https"
        }

        XCTAssertTrue(didOpen)
        XCTAssertEqual(opened, [
            "macappstore://apps.apple.com/app/id1234567890",
            "https://apps.apple.com/app/id1234567890",
        ])
    }

    func testOpenReturnsFalseWhenAllURLsFail() {
        let opener = AppStoreUpdateOpener(appID: "")
        var opened: [String] = []

        let didOpen = opener.open { url in
            opened.append(url.absoluteString)
            return false
        }

        XCTAssertFalse(didOpen)
        XCTAssertEqual(opened, [
            "https://apps.apple.com/search?term=SitWatcher",
        ])
    }
}
