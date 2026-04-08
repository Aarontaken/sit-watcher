import XCTest
@testable import SitWatcher

final class IdleDetectorTests: XCTestCase {

    func testSmallMouseMovementIsIgnored() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 100, y: 100)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 105, y: 103))
        XCTAssertFalse(moved, "Movement of ~5.8px should be ignored (threshold=10)")
    }

    func testLargeMouseMovementIsDetected() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 100, y: 100)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 120, y: 100))
        XCTAssertTrue(moved, "Movement of 20px should be detected")
    }

    func testExactThresholdIsIgnored() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 0, y: 0)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 6, y: 8))
        XCTAssertFalse(moved, "Movement of exactly 10px should be ignored (< not <=)")
    }

    func testJustOverThresholdIsDetected() {
        let detector = IdleDetector(mouseThreshold: 10.0)
        detector.lastMouseLocation = CGPoint(x: 0, y: 0)
        let moved = detector.isRealMouseMovement(to: CGPoint(x: 7, y: 8))
        XCTAssertTrue(moved, "Movement of ~10.6px should be detected")
    }
}
