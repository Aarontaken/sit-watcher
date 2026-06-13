import XCTest
@testable import SitWatcher

final class CharacterFramePlanTests: XCTestCase {
    func testStillImagePlanUsesOneFrame() {
        let plan = CharacterFramePlan.make(sourceDuration: nil, requestedStart: 0, sourceKind: .stillImage)
        XCTAssertEqual(plan.frameCount, 1)
        XCTAssertEqual(plan.frameInterval, 1)
        XCTAssertEqual(plan.sampleTimes, [0])
    }

    func testVideoPlanUsesThreeSecondsAndFortyFiveFrames() {
        let plan = CharacterFramePlan.make(sourceDuration: 10, requestedStart: 2, sourceKind: .video)
        XCTAssertEqual(plan.frameCount, 45)
        XCTAssertEqual(plan.duration, 3, accuracy: 0.001)
        XCTAssertEqual(plan.sampleTimes.first!, 2, accuracy: 0.001)
        XCTAssertEqual(plan.sampleTimes.last!, 4.933, accuracy: 0.01)
    }

    func testAnimatedImagePlanDefaultsToThreeSecondsWhenDurationIsUnknown() {
        let plan = CharacterFramePlan.make(sourceDuration: nil, requestedStart: 0, sourceKind: .animatedImage)
        XCTAssertEqual(plan.duration, 3, accuracy: 0.001)
        XCTAssertEqual(plan.frameCount, 45)
        XCTAssertEqual(plan.sampleTimes.first!, 0, accuracy: 0.001)
        XCTAssertEqual(plan.sampleTimes.last!, 2.933, accuracy: 0.01)
    }

    func testShortVideoPlanUsesAvailableDuration() {
        let plan = CharacterFramePlan.make(sourceDuration: 1.2, requestedStart: 0.8, sourceKind: .video)
        XCTAssertEqual(plan.duration, 0.4, accuracy: 0.001)
        XCTAssertEqual(plan.frameCount, 6)
    }

    func testVideoPlanClampsStartToLastAvailableSegment() {
        let plan = CharacterFramePlan.make(sourceDuration: 10, requestedStart: 10, sourceKind: .video)
        XCTAssertEqual(plan.duration, 3, accuracy: 0.001)
        XCTAssertEqual(plan.frameCount, 45)
        XCTAssertEqual(plan.sampleTimes.first!, 7, accuracy: 0.001)
        XCTAssertLessThanOrEqual(plan.sampleTimes.last!, 10)
    }

    func testShortVideoPlanClampsOutOfRangeStartToBeginning() {
        let plan = CharacterFramePlan.make(sourceDuration: 1.2, requestedStart: 2, sourceKind: .video)
        XCTAssertEqual(plan.duration, 1.2, accuracy: 0.001)
        XCTAssertEqual(plan.frameCount, 18)
        XCTAssertEqual(plan.sampleTimes.first!, 0, accuracy: 0.001)
        XCTAssertLessThanOrEqual(plan.sampleTimes.last!, 1.2)
    }

    func testCropClampsOffsetWithinSquareStage() {
        let crop = CharacterCrop(scale: 1.5, offsetX: 3, offsetY: -3, shape: .circle)
        let clamped = CharacterFramePlan.clampedCrop(crop)
        XCTAssertEqual(clamped.offsetX, 0.5, accuracy: 0.001)
        XCTAssertEqual(clamped.offsetY, -0.5, accuracy: 0.001)
    }

    func testCropClampsScaleBounds() {
        XCTAssertEqual(
            CharacterFramePlan.clampedCrop(CharacterCrop(scale: 0.25, offsetX: 0, offsetY: 0, shape: .square)).scale,
            1
        )
        XCTAssertEqual(
            CharacterFramePlan.clampedCrop(CharacterCrop(scale: 12, offsetX: 0, offsetY: 0, shape: .square)).scale,
            4
        )
    }
}
