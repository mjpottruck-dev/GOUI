import SwiftUI

struct SelectablePlayerChip: View {
    let player: Player
    let isSelected: Bool
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GoStatsTheme.teal.opacity(0.16))
                    .overlay(
                        Circle().stroke(GoStatsTheme.teal.opacity(0.30), lineWidth: 1)
                    )

                Text("\(player.number)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GoStatsTheme.text)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? GoStatsTheme.teal : GoStatsTheme.text2.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? GoStatsTheme.teal.opacity(0.35) : GoStatsTheme.stroke.opacity(0.25), lineWidth: 1)
        )
    }
}
