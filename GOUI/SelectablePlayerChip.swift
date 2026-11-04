import SwiftUI

struct SelectablePlayerChip: View {
    let player: Player
    let isSelected: Bool
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GoStatsTheme.primary.opacity(0.08))
                    .overlay(
                        Circle().stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
                    )

                Text("\(player.number)")
                    .font(.custom("DM Mono", size: 14))
                    .foregroundStyle(GoStatsTheme.text)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.custom("DM Sans", size: 15).weight(.medium))
                    .foregroundStyle(GoStatsTheme.text)

                if let subtitle {
                    Text(subtitle)
                        .font(.custom("DM Sans", size: 12))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? GoStatsTheme.primary : GoStatsTheme.text2.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .stroke(isSelected ? GoStatsTheme.primary.opacity(0.35) : GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
        )
    }
}
