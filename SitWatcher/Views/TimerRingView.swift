import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let formattedTime: String
    let ringSize: CGFloat

    private let lineWidth: CGFloat = 8

    private let accentGreen = Color(red: 0.20, green: 0.78, blue: 0.45)
    private let accentCyan = Color(red: 0.05, green: 0.72, blue: 0.78)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [accentGreen, accentCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .shadow(color: accentGreen.opacity(0.4), radius: 6, x: 0, y: 0)

            VStack(spacing: 2) {
                Text(formattedTime)
                    .font(.system(size: ringSize * 0.24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Text("剩余时间")
                    .font(.system(size: ringSize * 0.08))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}
