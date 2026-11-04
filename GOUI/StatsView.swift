import SwiftUI

struct StatsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var selectedSeasonID: UUID? = nil
    @State private var showFullLeaderboard: Bool = false

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
        return team.players.compactMap { player -> (Player, Int)? in
            guard let goals = totals[player.id], goals > 0 else { return nil }
            return (player, goals)
        }
        .sorted { $0.1 > $1.1 }
    }

    private var totalGF: Int { matches.reduce(0) { $0 + $1.goalsFor } }
    private var totalGA: Int { matches.reduce(0) { $0 + $1.goalsAgainst } }

    // Aggregate all player stats across matches
    private var allPlayerRows: [(player: Player, goals: Int, assists: Int, shots: Int, sot: Int, saves: Int, conceded: Int, mins: Int)] {
        guard let team else { return [] }
        var agg: [UUID: (g: Int, a: Int, sh: Int, sot: Int, sv: Int, gc: Int, sec: Int)] = [:]
        for match in matches {
            for (pid, line) in match.playerStats {
                var cur = agg[pid, default: (0, 0, 0, 0, 0, 0, 0)]
                cur.g += line.goals
                cur.a += line.assists
                cur.sh += line.shots
                cur.sot += line.shotsOnTarget
                cur.sv += line.saves
                cur.gc += line.goalsConceded
                cur.sec += match.playerSeconds[pid] ?? 0
                agg[pid] = cur
            }
        }
        return team.players.compactMap { p in
            guard let s = agg[p.id] else { return nil }
            guard s.g > 0 || s.a > 0 || s.sh > 0 || s.sv > 0 || s.gc > 0 || s.sec > 0 else { return nil }
            return (p, s.g, s.a, s.sh, s.sot, s.sv, s.gc, s.sec / 60)
        }
        .sorted { $0.goals != $1.goals ? $0.goals > $1.goals : $0.player.number < $1.player.number }
    }

    // Team leader values for progress ring scaling
    private var maxGoals: Int { allPlayerRows.map(\.goals).max() ?? 0 }
    private var maxAssists: Int { allPlayerRows.map(\.assists).max() ?? 0 }
    private var maxShots: Int { allPlayerRows.map(\.shots).max() ?? 0 }
    private var maxSaves: Int { allPlayerRows.map(\.saves).max() ?? 0 }
    private var maxConceded: Int { allPlayerRows.map(\.conceded).max() ?? 0 }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // 1. Season pill picker
                    seasonPill

                    // 2. Three metric cards
                    metricCardsRow

                    // 2b. Season Stats link
                    seasonStatsLink

                    // 3. Top Scorers
                    topScorersCard

                    // 4. Player Stats
                    playerStatsCard

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

    // MARK: - Season Pill Picker

    private var seasonPill: some View {
        HStack {
            if seasons.isEmpty {
                Text("No seasons")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(GoStatsTheme.textMuted)
            } else {
                Picker("Season", selection: Binding(
                    get: { selectedSeasonID ?? seasons.first?.id },
                    set: { newValue in
                        selectedSeasonID = newValue
                        if let newValue { teamStore.setActiveSeason(newValue) }
                    }
                )) {
                    ForEach(seasons) { season in
                        Text(season.name).tag(Optional(season.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(GoStatsTheme.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(GoStatsTheme.surface)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Metric Cards Row

    private var metricCardsRow: some View {
        HStack(spacing: 10) {
            metricCard(value: matches.count, label: "Matches")
            metricCard(value: totalGF, label: "Goals For")
            metricCard(value: totalGA, label: "Goals Against")
        }
    }

    private func metricCard(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color(hex: "1a1a1a"))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "aaaaaa"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor,
                        radius: GoStatsTheme.cardShadowRadius,
                        x: 0, y: GoStatsTheme.cardShadowY)
        )
    }

    // MARK: - Season Stats Link

    private var seasonStatsLink: some View {
        NavigationLink {
            SeasonStatsView(teamStore: teamStore, teamID: teamID)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(GoStatsTheme.surface))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Season Stats")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                    Text("Record, form, scorers & goalkeeping")
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Scorers Card

    private var topScorersCard: some View {
        GoStatsTheme.card {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader("TOP SCORERS")

                if leaderboard.isEmpty {
                    emptyState(icon: "soccerball", text: "No goals yet this season.")
                } else {
                    let visible = showFullLeaderboard ? leaderboard : Array(leaderboard.prefix(5))
                    VStack(spacing: 0) {
                        ForEach(Array(visible.enumerated()), id: \.offset) { index, entry in
                            if index > 0 {
                                Rectangle()
                                    .fill(GoStatsTheme.divider)
                                    .frame(height: 0.5)
                            }
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                                    .frame(width: 24, alignment: .leading)

                                Text(entry.player.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)

                                Spacer()

                                Text("\(entry.goals)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                            .padding(.vertical, 10)
                        }
                    }

                    if leaderboard.count > 5 {
                        Button {
                            withAnimation(.easeInOut) { showFullLeaderboard.toggle() }
                        } label: {
                            Text(showFullLeaderboard ? "Show Top 5" : "View All")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(GoStatsTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Player Stats Card

    private var playerStatsCard: some View {
        GoStatsTheme.card {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader("PLAYER STATS")

                if allPlayerRows.isEmpty {
                    emptyState(icon: "person.3", text: "No player stats yet.")
                } else {
                    VStack(spacing: 0) {
                        ForEach(0..<allPlayerRows.count, id: \.self) { index in
                            let row = allPlayerRows[index]
                            if index > 0 {
                                Rectangle()
                                    .fill(GoStatsTheme.divider)
                                    .frame(height: 0.5)
                            }
                            HStack(spacing: 12) {
                                // Jersey number circle
                                ZStack {
                                    Circle()
                                        .fill(GoStatsTheme.textPrimary)
                                        .frame(width: 36, height: 36)
                                    Text("\(row.player.number)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                                // Name + position
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.player.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                        .lineLimit(1)
                                    Text(row.player.position.rawValue)
                                        .font(.system(size: 11))
                                        .foregroundStyle(GoStatsTheme.textMuted)
                                }
                                .layoutPriority(-1)

                                Spacer()

                                // Progress rings — GK gets Saves/Conceded/Save%, others get G/A/Sh
                                HStack(spacing: 10) {
                                    if row.player.position == .gk {
                                        ProgressRingView(
                                            value: row.saves,
                                            max: Swift.max(maxSaves, 1),
                                            color: GoStatsTheme.ringGoals,
                                            label: "Sv"
                                        )
                                        ProgressRingView(
                                            value: row.conceded,
                                            max: Swift.max(maxConceded, 1),
                                            color: GoStatsTheme.ringConceded,
                                            label: "GA"
                                        )
                                        PercentRingView(
                                            saves: row.saves,
                                            conceded: row.conceded,
                                            color: GoStatsTheme.ringAssists
                                        )
                                    } else {
                                        ProgressRingView(
                                            value: row.goals,
                                            max: Swift.max(maxGoals, 1),
                                            color: GoStatsTheme.ringGoals,
                                            label: "G"
                                        )
                                        ProgressRingView(
                                            value: row.assists,
                                            max: Swift.max(maxAssists, 1),
                                            color: GoStatsTheme.ringAssists,
                                            label: "A"
                                        )
                                        ProgressRingView(
                                            value: row.shots,
                                            max: Swift.max(maxShots, 1),
                                            color: GoStatsTheme.ringShots,
                                            label: "Sh"
                                        )
                                    }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 10)
                        }
                    }

                    // NavigationLink to TeamStatsView
                    if let team {
                        NavigationLink {
                            TeamStatsView(team: team)
                        } label: {
                            HStack {
                                Text("View detailed stats")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(GoStatsTheme.emptyStateColor)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(GoStatsTheme.emptyStateColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Progress Ring View

private struct ProgressRingView: View {
    let value: Int
    let max: Int
    let color: Color
    let label: String

    private var progress: Double {
        max > 0 ? Double(value) / Double(max) : 0
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(GoStatsTheme.ringTrack, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(value)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
            }
            .frame(width: 44, height: 44)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(GoStatsTheme.textMuted)
        }
    }
}

// MARK: - Percent Ring View (for GK Save %)

private struct PercentRingView: View {
    let saves: Int
    let conceded: Int
    let color: Color

    private var pct: Int {
        let total = saves + conceded
        guard total > 0 else { return 0 }
        return Int(round(Double(saves) / Double(total) * 100))
    }

    private var progress: Double {
        Double(pct) / 100.0
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(GoStatsTheme.ringTrack, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(pct)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
            }
            .frame(width: 44, height: 44)
            Text("Sv%")
                .font(.system(size: 9))
                .foregroundStyle(GoStatsTheme.textMuted)
        }
    }
}
