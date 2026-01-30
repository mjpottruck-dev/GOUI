import SwiftUI

struct StatsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    let sport: any SportDefinition

    @State private var selectedSeasonID: UUID? = nil
    @State private var showFullLeaderboard: Bool = false
    @State private var showPricing = false

    @EnvironmentObject var subscriptionManager: SubscriptionManager

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var seasons: [Season] {
        teamStore.seasons(for: teamID)
    }

    private var matches: [MatchRecord] {
        guard let team else { return [] }
        guard let selectedSeasonID else { return team.matches }
        return team.matches.filter { $0.seasonID == selectedSeasonID }
    }

    private var leaderboard: [(player: Player, value: Int)] {
        guard let team else { return [] }
        var totals: [UUID: Int] = [:]
        for match in matches {
            for (pid, line) in match.playerStats {
                totals[pid, default: 0] += line.value(for: sport.scoringRules.primaryStatID)
            }
        }
        let players = team.players.compactMap { player -> (Player, Int)? in
            guard let value = totals[player.id], value > 0 else { return nil }
            return (player, value)
        }
        return players.sorted { $0.1 > $1.1 }
    }

    private var podium: [(player: Player, value: Int)] {
        Array(leaderboard.prefix(3))
    }

    private var spotlightPlayer: Player? {
        leaderboard.first?.player ?? team?.players.first
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            if subscriptionManager.entitlements.advancedAnalytics {
                ScrollView {
                    VStack(spacing: 16) {
                        seasonCard
                        podiumCard
                        leaderboardCard
                        summaryCard
                        advancedAnalyticsCard
                        playerStatsCard
                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 140)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        UpgradePromptView(
                            title: "Advanced Analytics",
                            message: "Upgrade to Pro to unlock full season stats, leaderboards, and player analytics.",
                            buttonTitle: "Upgrade"
                        ) {
                            showPricing = true
                        }
                        summaryCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedSeasonID == nil {
                selectedSeasonID = teamStore.activeSeasonID(for: teamID) ?? seasons.first?.id
            }
        }
        .sheet(isPresented: $showPricing) {
            PricingView()
                .environmentObject(subscriptionManager)
        }
    }

    private var seasonCard: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("SEASON")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if seasons.isEmpty {
                    Text("No seasons available")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    Picker("Season", selection: Binding(
                        get: { selectedSeasonID ?? seasons.first?.id },
                        set: { newValue in
                            selectedSeasonID = newValue
                            if let newValue {
                                teamStore.setActiveSeason(newValue, for: teamID)
                            }
                        }
                    )) {
                        ForEach(seasons) { season in
                            Text(season.name).tag(Optional(season.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var podiumCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TOP \(primaryStatType.displayName.uppercased())")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if podium.isEmpty {
                    Text("No \(primaryStatType.displayName.lowercased()) yet this season.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    HStack(spacing: 10) {
                        ForEach(Array(podium.enumerated()), id: \.offset) { index, entry in
                            podiumChip(rank: index + 1, player: entry.player, value: entry.value)
                        }
                    }
                }
            }
        }
    }

    private var leaderboardCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("LEADERBOARD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if leaderboard.isEmpty {
                    Text("No \(primaryStatType.displayName.lowercased()) yet. Save a match to populate stats.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    VStack(spacing: 8) {
                        let visible = showFullLeaderboard ? leaderboard : Array(leaderboard.prefix(5))
                        ForEach(Array(visible.enumerated()), id: \.offset) { index, entry in
                            leaderboardRow(rank: index + 1, player: entry.player, value: entry.value)
                        }

                        if leaderboard.count > 5 {
                            Button {
                                withAnimation(.easeInOut) {
                                    showFullLeaderboard.toggle()
                                }
                            } label: {
                                Text(showFullLeaderboard ? "Show Top 5" : "View All")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SUMMARY")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                HStack(spacing: 10) {
                    statChip("Matches", "\(matches.count)")
                    statChip("\(sport.scoringRules.scoreLabel) For", "\(matches.reduce(0) { $0 + $1.goalsFor })")
                    statChip("\(sport.scoringRules.scoreLabel) Against", "\(matches.reduce(0) { $0 + $1.goalsAgainst })")
                }
            }
        }
    }

    private var playerStatsCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("PLAYER STATS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if let team {
                    NavigationLink {
                        TeamStatsView(team: team, sport: sport)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.primary)
                            Text("View individual stats")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Select a team to view player stats.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private var advancedAnalyticsCard: some View {
        Group {
            if let team {
                AdvancedAnalyticsDashboardView(
                    team: team,
                    sport: sport,
                    matches: matches,
                    seasons: seasons,
                    spotlightPlayer: spotlightPlayer
                )
            } else {
                LiquidGlassContainer(cornerRadius: 22) {
                    Text("Select a team to view analytics.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private func podiumChip(rank: Int, player: Player, value: Int) -> some View {
        VStack(spacing: 6) {
            Text("#\(rank)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(player.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
                .lineLimit(1)
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private func leaderboardRow(rank: Int, player: Player, value: Int) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text2)
                .frame(width: 32, alignment: .leading)

            Text(player.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)

            Spacer()

            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.50))
        )
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private var primaryStatType: StatType {
        sport.statSchema.first(where: { $0.id == sport.scoringRules.primaryStatID })
            ?? StatType(id: sport.scoringRules.primaryStatID, displayName: sport.scoringRules.scoreLabel, shortLabel: nil, countsForTeam: true, countsForPlayer: true)
    }
}
