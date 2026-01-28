import SwiftUI

struct StatsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var selectedSeasonID: UUID? = nil

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var seasons: [Season] {
        teamStore.seasons
    }

    private var matches: [MatchRecord] {
        guard let team else { return [] }
        guard let selectedSeasonID else { return team.matches }
        return team.matches.filter { $0.seasonID == selectedSeasonID }
    }

    private var leaderboard: [(player: Player, goals: Int)] {
        guard let team else { return [] }
        var totals: [UUID: Int] = [:]
        for match in matches {
            for (pid, line) in match.playerStats {
                totals[pid, default: 0] += line.goals
            }
        }
        let players = team.players.compactMap { player -> (Player, Int)? in
            guard let goals = totals[player.id], goals > 0 else { return nil }
            return (player, goals)
        }
        return players.sorted { $0.1 > $1.1 }
    }

    private var podium: [(player: Player, goals: Int)] {
        Array(leaderboard.prefix(3))
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    seasonCard
                    podiumCard
                    leaderboardCard
                    summaryCard
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedSeasonID == nil {
                selectedSeasonID = teamStore.activeSeasonID ?? seasons.first?.id
            }
        }
    }

    private var seasonCard: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("SEASON")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

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
                                teamStore.setActiveSeason(newValue)
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
                Text("TOP SCORERS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                if podium.isEmpty {
                    Text("No goals yet this season.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    HStack(spacing: 10) {
                        ForEach(Array(podium.enumerated()), id: \.offset) { index, entry in
                            podiumChip(rank: index + 1, player: entry.player, goals: entry.goals)
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
                    .foregroundStyle(GoStatsTheme.text2)

                if leaderboard.isEmpty {
                    Text("No scorers yet. Save a match to populate stats.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(leaderboard.enumerated()), id: \.offset) { index, entry in
                            leaderboardRow(rank: index + 1, player: entry.player, goals: entry.goals)
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
                    .foregroundStyle(GoStatsTheme.text2)

                HStack(spacing: 10) {
                    statChip("Matches", "\(matches.count)")
                    statChip("Goals For", "\(matches.reduce(0) { $0 + $1.goalsFor })")
                    statChip("Goals Against", "\(matches.reduce(0) { $0 + $1.goalsAgainst })")
                }
            }
        }
    }

    private func podiumChip(rank: Int, player: Player, goals: Int) -> some View {
        VStack(spacing: 6) {
            Text("#\(rank)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(player.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
                .lineLimit(1)
            Text("\(goals)")
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

    private func leaderboardRow(rank: Int, player: Player, goals: Int) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text2)
                .frame(width: 32, alignment: .leading)

            Text(player.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)

            Spacer()

            Text("\(goals)")
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
}
