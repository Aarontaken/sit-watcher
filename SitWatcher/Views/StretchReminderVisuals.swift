import Combine
import SwiftUI

/// Shared interval for swapping `figure.flexibility` ↔ `figure.cooldown` (panels + menu bar logic).
enum StretchFigureTiming {
    static let swapInterval: TimeInterval = 0.48
}

final class StretchFigureTicker: ObservableObject {
    @Published private(set) var useFlexibility = true
    private var cancellables = Set<AnyCancellable>()

    func start() {
        stop()
        Timer.publish(every: StretchFigureTiming.swapInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] (_: Date) in
                self?.useFlexibility.toggle()
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
    }
}

enum StretchReminderHeroLayout {
    /// Stable square slot for swapping SF Symbols (`flexibility` / `cooldown` have different glyph bounds).
    static func slotSide(symbolFontPoints: CGFloat) -> CGFloat {
        ceil(symbolFontPoints * 1.52 + 28)
    }
}

/// Large playful animated stretch figure for reminder surfaces (not menu bar template).
struct StretchReminderHeroFigure: View {
    @ObservedObject var ticker: StretchFigureTicker
    let size: CGFloat
    var reduceMotionAware: Bool = true

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let peach = Color(red: 1.0, green: 0.65, blue: 0.42)

    private var slot: CGFloat {
        StretchReminderHeroLayout.slotSide(symbolFontPoints: size)
    }

    var body: some View {
        let symbol = accessibilityReduceMotion && reduceMotionAware
            ? "figure.flexibility"
            : (ticker.useFlexibility ? "figure.flexibility" : "figure.cooldown")

        ZStack {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .bold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(
                    LinearGradient(
                        colors: [mint, cyan, peach],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: mint.opacity(0.45), radius: size * 0.16, y: size * 0.04)
                .shadow(color: cyan.opacity(0.28), radius: size * 0.26)
                .scaleEffect(scaleAmount)
                .animation(motionAnimation, value: ticker.useFlexibility)
        }
        .frame(width: slot, height: slot)
    }

    private var scaleAmount: CGFloat {
        if accessibilityReduceMotion && reduceMotionAware { return 1.0 }
        return ticker.useFlexibility ? 1.06 : 1.02
    }

    private var motionAnimation: Animation {
        if accessibilityReduceMotion && reduceMotionAware {
            .linear(duration: 0.001)
        } else {
            .spring(response: 0.44, dampingFraction: 0.58)
        }
    }
}
