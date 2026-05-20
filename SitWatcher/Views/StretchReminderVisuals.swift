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

enum StretchReminderHeroGlyphSwapStyle {
    /// Single `Image`; fine for floating panel (one hosting root).
    case replaceSymbol
    /// Layered symbols with opaque toggles — harmless belt-and-suspenders when swapping glyphs frequently.
    case dualOpacityLayers
}

enum StretchReminderHeroShadowProfile {
    /// Floating panel: stronger depth cues.
    case panel
    /// Fullscreen hero: skip SwiftUI shadow stacks (depth comes from gradients only).
    case fullscreenFlat
}

enum StretchReminderHeroLayout {
    /// Stable square slot for swapping SF Symbols (`flexibility` / `cooldown` have different glyph bounds).
    static func slotSide(symbolFontPoints: CGFloat) -> CGFloat {
        ceil(symbolFontPoints * 1.52 + 28)
    }
}

struct StretchReminderHeroFigure: View {
    @ObservedObject var ticker: StretchFigureTicker
    let size: CGFloat
    var reduceMotionAware: Bool = true
    /// Fullscreen renders across multiple independent `NSHostingView` roots; keep SwiftUI shadow stacks minimal here.
    var shadowProfile: StretchReminderHeroShadowProfile = .panel
    /// Prefer `.dualOpacityLayers` when swapping glyphs frequently on fullscreen surfaces.
    var glyphSwapStyle: StretchReminderHeroGlyphSwapStyle = .replaceSymbol

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private let mint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let cyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let peach = Color(red: 1.0, green: 0.65, blue: 0.42)

    private var slot: CGFloat {
        StretchReminderHeroLayout.slotSide(symbolFontPoints: size)
    }

    private var symbol: String {
        if accessibilityReduceMotion && reduceMotionAware { return "figure.flexibility" }
        return ticker.useFlexibility ? "figure.flexibility" : "figure.cooldown"
    }

    private func gradientSymbol(named systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .bold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(
                LinearGradient(
                    colors: [mint, cyan, peach],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    @ViewBuilder
    private var scaledGlyph: some View {
        if accessibilityReduceMotion && reduceMotionAware {
            gradientSymbol(named: "figure.flexibility")
        } else if glyphSwapStyle == .dualOpacityLayers {
            ZStack {
                gradientSymbol(named: "figure.flexibility")
                    .opacity(ticker.useFlexibility ? 1 : 0)
                    .animation(nil, value: ticker.useFlexibility)
                gradientSymbol(named: "figure.cooldown")
                    .opacity(ticker.useFlexibility ? 0 : 1)
                    .animation(nil, value: ticker.useFlexibility)
            }
            .scaleEffect(scaleAmount)
            .animation(motionAnimation, value: scaleAmount)
        } else {
            gradientSymbol(named: symbol)
                .id(symbol)
                .scaleEffect(scaleAmount)
                .animation(motionAnimation, value: scaleAmount)
        }
    }

    var body: some View {
        ZStack {
            Group {
                switch shadowProfile {
                case .panel:
                    scaledGlyph
                        .compositingGroup()
                        .shadow(color: mint.opacity(0.45), radius: size * 0.16, y: size * 0.04)
                        .shadow(color: cyan.opacity(0.28), radius: size * 0.26)
                case .fullscreenFlat:
                    scaledGlyph
                }
            }
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
