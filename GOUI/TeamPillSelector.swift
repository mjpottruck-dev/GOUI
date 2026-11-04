import SwiftUI

/// Horizontally scrollable team pill selector (replaces dropdown Menu).
struct TeamPillSelector: View {
    let teams: [Team]
    @Binding var selectedTeamID: UUID?
    var onCreateTeam: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(teams) { team in
                    let isSelected = team.id == selectedTeamID
                    Button {
                        GoStatsTheme.hapticTap()
                        selectedTeamID = team.id
                    } label: {
                        Text(team.name)
                            .font(.custom("DM Sans", size: 14).weight(.medium))
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? .white : GoStatsTheme.text)
                            .background(
                                Capsule()
                                    .fill(isSelected ? GoStatsTheme.textPrimary : Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor,
                                            radius: GoStatsTheme.cardShadowRadius,
                                            x: 0, y: GoStatsTheme.cardShadowY)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : GoStatsTheme.cardBorder,
                                            lineWidth: GoStatsTheme.cardBorderWidth)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // "+" create team button
                if let onCreateTeam {
                    Button {
                        GoStatsTheme.hapticTap()
                        onCreateTeam()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.textMuted)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor,
                                            radius: GoStatsTheme.cardShadowRadius,
                                            x: 0, y: GoStatsTheme.cardShadowY)
                            )
                            .overlay(
                                Circle()
                                    .stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
