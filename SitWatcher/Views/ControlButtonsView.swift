import SwiftUI

struct ControlButtonsView: View {
    let isPaused: Bool
    var onPauseToggle: () -> Void
    var onSkip: () -> Void
    var onReset: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            controlButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                label: isPaused ? "继续" : "暂停",
                action: onPauseToggle
            )
            controlButton(icon: "forward.end.fill", label: "跳过", action: onSkip)
            controlButton(icon: "arrow.counterclockwise", label: "重置", action: onReset)
        }
    }

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
