import Foundation
import CoreGraphics
import AppKit

final class IdleDetector {
    private(set) var isUserIdle: Bool = false
    private var lastMouseLocation: CGPoint = .zero

    private let mouseThreshold: Double
    private var idleAccumulator: TimeInterval = 0
    private var pollTimer: Timer?
    private let pollInterval: TimeInterval = 1.0

    var onIdleStateChanged: ((Bool) -> Void)?

    init(mouseThreshold: Double = 10.0) {
        self.mouseThreshold = mouseThreshold
    }

    func start(idleThreshold: TimeInterval) {
        lastMouseLocation = NSEvent.mouseLocation
        idleAccumulator = 0
        isUserIdle = false

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.tick(idleThreshold: idleThreshold)
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func isRealMouseMovement(to newLocation: CGPoint) -> Bool {
        let dx = newLocation.x - lastMouseLocation.x
        let dy = newLocation.y - lastMouseLocation.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance > mouseThreshold
    }

    private func tick(idleThreshold: TimeInterval) {
        let currentLocation = NSEvent.mouseLocation
        let keyboardIdle = CGEventSource.secondsSinceLastEventType(
            .hidSystemState, eventType: .keyDown
        )

        let hasRealMovement = isRealMouseMovement(to: currentLocation)
        let hasKeyboard = keyboardIdle < pollInterval * 2

        lastMouseLocation = currentLocation

        if hasRealMovement || hasKeyboard {
            idleAccumulator = 0
            if isUserIdle {
                isUserIdle = false
                onIdleStateChanged?(false)
            }
        } else {
            idleAccumulator += pollInterval
            if !isUserIdle && idleAccumulator >= idleThreshold {
                isUserIdle = true
                onIdleStateChanged?(true)
            }
        }
    }
}
