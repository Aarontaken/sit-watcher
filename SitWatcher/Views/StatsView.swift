import SwiftUI

struct StatsView: View {
    let restCount: Int
    let interruptCount: Int
    let focusSeconds: TimeInterval

    private var focusDisplay: String {
        let hours = Int(focusSeconds) / 3600
        let mins = (Int(focusSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours).\(mins / 6)h"
        }
        return "\(mins)min"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日统计")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack {
                statItem(value: "\(restCount)", label: "已休息", color: .green)
                Spacer()
                statItem(value: "\(interruptCount)", label: "被打断", color: .orange)
                Spacer()
                statItem(value: focusDisplay, label: "专注时长", color: .white)
            }
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
