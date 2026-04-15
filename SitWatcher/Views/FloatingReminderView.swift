import SwiftUI

struct FloatingReminderView: View {
    let sittingMinutes: Int
    let canSnooze: Bool
    var onConfirm: () -> Void
    var onSnooze: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🧍‍♂️")
                .font(.system(size: 48))
                .padding(.top, 4)

            VStack(spacing: 8) {
                Text("该站起来了！")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("你已经连续坐了 \(sittingMinutes) 分钟")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            HStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text("好的，我去活动")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                if canSnooze {
                    Button(action: onSnooze) {
                        Text("稍后 5 分钟")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
