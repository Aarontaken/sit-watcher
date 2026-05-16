import SwiftUI

struct FullScreenOverlayView: View {
    let sittingMinutes: Int
    var onDismiss: () -> Void

    @StateObject private var figureTicker = StretchFigureTicker()
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private let accentMint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let accentCyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let accentPeach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)

            RadialGradient(
                colors: [
                    accentMint.opacity(0.16),
                    accentCyan.opacity(0.06),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )

            RadialGradient(
                colors: [accentPeach.opacity(0.08), Color.clear],
                center: UnitPoint(x: 0.15, y: 0.85),
                startRadius: 20,
                endRadius: 300
            )

            VStack(spacing: 24) {
                StretchReminderHeroFigure(ticker: figureTicker, size: 112)

                Text("起来走走吧")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, accentMint.opacity(0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("已经坐了 \(sittingMinutes) 分钟，给身体一点活动的时间")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onDismiss) {
                    Text("我已经站起来了")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black.opacity(0.88))
                        .padding(.horizontal, 34)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [
                                    accentMint,
                                    accentCyan.opacity(0.9),
                                    accentPeach.opacity(0.82)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accentMint.opacity(0.45), radius: 16, y: 5)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if accessibilityReduceMotion == false {
                figureTicker.start()
            }
        }
        .onDisappear {
            figureTicker.stop()
        }
    }
}
