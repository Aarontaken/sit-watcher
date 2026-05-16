import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let formattedTime: String
    let ringSize: CGFloat

    private let lineWidth: CGFloat = 8

    private let accentMint = Color(red: 0.22, green: 0.98, blue: 0.62)
    private let accentCyan = Color(red: 0.12, green: 0.78, blue: 1.0)
    private let accentPeach = Color(red: 1.0, green: 0.55, blue: 0.45)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [accentMint, accentCyan, accentPeach.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .shadow(color: accentMint.opacity(0.42), radius: 8, x: 0, y: 0)
                .shadow(color: accentCyan.opacity(0.28), radius: 4, x: 0, y: 2)

            RadialGradient(
                colors: [
                    accentMint.opacity(0.12),
                    accentCyan.opacity(0.06),
                    Color.clear
                ],
                center: .center,
                startRadius: ringSize * 0.05,
                endRadius: ringSize * 0.38
            )

            VStack(spacing: 3) {
                Text(formattedTime)
                    .font(.system(size: ringSize * 0.24, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, accentMint.opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()

                Text("剩余时间")
                    .font(.system(size: ringSize * 0.08, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}
