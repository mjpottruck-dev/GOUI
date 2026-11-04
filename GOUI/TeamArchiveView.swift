import SwiftUI

struct TeamArchiveView: View {
    var teamStore: TeamStore
    let teamID: UUID

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            if let team {
                ScrollView {
                    VStack(spacing: GoStatsTheme.cardGap) {
                        if team.matches.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.system(size: 28))
                                    .foregroundStyle(GoStatsTheme.emptyStateColor)
                                Text("No saved matches yet.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.emptyStateColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(team.matches) { match in
                                NavigationLink {
                                    MatchGameDetailView(match: match, team: team)
                                } label: {
                                    VStack(spacing: 12) {
                                        Text("\(team.name) vs \(match.opponent.isEmpty ? "Opponent" : match.opponent)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(GoStatsTheme.textPrimary)

                                        Text("\(match.goalsFor) - \(match.goalsAgainst)")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundStyle(GoStatsTheme.textPrimary)

                                        HStack(spacing: 12) {
                                            Text(match.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.system(size: 13))
                                                .foregroundStyle(GoStatsTheme.textMuted)
                                            if !match.venue.isEmpty {
                                                Text(match.venue)
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(GoStatsTheme.textMuted)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(GoStatsTheme.cardPadding)
                                    .background(
                                        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                            .fill(Color.white)
                                            .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, GoStatsTheme.cardMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28))
                        .foregroundStyle(GoStatsTheme.emptyStateColor)
                    Text("Team not found.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                    Text("Create a team first.")
                        .font(.system(size: 13))
                        .foregroundStyle(GoStatsTheme.emptyStateColor)
                }
            }
        }
        .navigationTitle("Match Archive")
        .navigationBarTitleDisplayMode(.inline)
    }
}
