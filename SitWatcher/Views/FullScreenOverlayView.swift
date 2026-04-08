import SwiftUI

struct FullScreenOverlayView: View {
    let sittingMinutes: Int
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)

            RadialGradient(
                colors: [
                    Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.08),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )

            VStack(spacing: 24) {
                Text("🚶")
                    .font(.system(size: 64))

                Text("起来走走吧")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("已经坐了 \(sittingMinutes) 分钟，你的身体需要活动")
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)

                Button(action: onDismiss) {
                    Text("我已经站起来了")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.87, blue: 0.50),
                                    Color(red: 0.13, green: 0.83, blue: 0.87)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .ignoresSafeArea()
    }
}
