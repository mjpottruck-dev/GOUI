import SwiftUI

/// A dedicated season-level stats screen. Unlike `StatsView` (the Stats tab), this
/// focuses on team performance for a single season: record, goal difference, recent
/// form, leaderboards, and goalkeeping — all filtered by the selected season.
struct SeasonStatsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var selectedSeasonID: UUID? = nil

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var seasons: [Season] {
        teamStore.seasons
    }

    /// Matches for the selected season (all matches when no season is chosen),
    /// sorted most-recent-first so "recent form" reads left-to-right newest→oldest.
    private var matches: [MatchRecord] {
        guard let team else { return [] }
        let filtered: [MatchRecord]
        if let selectedSeasonID {
            filtered = team.matches.filter { $0.seasonID == selectedSeasonID }
        } else {
            filtered = team.matches
        }
        return filtered.sorted { $0.date > $1.date }
    }

    // MARK: - Aggregates

    private var wins: Int { matches.filter { $0.goalsFor > $0.goalsAgainst }.count }
    private var draws: Int { matches.filter { $0.goalsFor == $0.goalsAgainst }.count }
    private var losses: Int { matches.filter { $0.goalsFor < $0.goalsAgainst }.count }

    private var totalGF: Int { matches.reduce(0) { $0 + $1.goalsFor } }
    private var totalGA: Int { matches.reduce(0) { $0 + $1.goalsAgainst } }
    private var goalDiff: Int { totalGF - totalGA }
    private var cleanSheets: Int { matches.filter { $0.goalsAgainst == 0 }.count }

    private var winPct: Int {
        guard !matches.isEmpty else { return 0 }
        return Int(round(Double(wins) / Double(matches.count) * 100))
    }

    private var avgGoalsFor: Double {
        guard !matches.isEmpty else { return 0 }
        return Double(totalGF) / Double(matches.count)
    }

    private var avgGoalsAgainst: Double {
        guard !matches.isEmpty else { return 0 }
        return Double(totalGA) / Double(matches.count)
    }

    /// Top scorers for the season, highest first.
    private var scorers: [(player: Player, value: Int)] {
        leaders(\.goals)
    }

    /// Top assisters for the season, highest first.
    private var assisters: [(player: Player, value: Int)] {
        leaders(\.assists)
    }

    private func leaders(_ key: KeyPath<PlayerStatLine, Int>) -> [(player: Player, value: Int)] {
        guard let team else { return [] }
        var totals: [UUID: Int] = [:]
        for match in matches {
            for (pid, line) in match.playerStats {
                totals[pid, default: 0] += line[keyPath: key]
            }
        }
        return team.players.compactMap { player -> (player: Player, value: Int)? in
            guard let value = totals[player.id], value > 0 else { return nil }
            return (player, value)
        }
        .sorted { $0.value > $1.value }
    }

    private var gkSavePct: Int {
        guard let team else { return 0 }
        var saves = 0, conceded = 0
        for match in matches {
            for (pid, line) in match.playerStats {
                if team.players.first(where: { $0.id == pid })?.position == .gk {
                    saves += line.saves
                    conceded += line.goalsConceded
                }
            }
        }
        let total = saves + conceded
        return total > 0 ? Int(round(Double(saves) / Double(total) * 100)) : 0
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    seasonPill

                    if matches.isEmpty {
                        emptyState
                    } else {
                        recordCard
                        summaryGrid
                        formCard
                        leaderboardCard(title: "TOP SCORERS",
                                        rows: scorers,
                                        unit: "goals",
                                        emptyText: "No goals this season.")
                        leaderboardCard(title: "TOP ASSISTS",
                                        rows: assisters,
                                        unit: "assists",
                                        emptyText: "No assists this season.")
                        goalkeeperCard
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Season Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedSeasonID == nil {
                selectedSeasonID = teamStore.activeSeasonID ?? seasons.first?.id
            }
        }
    }

    // MARK: - Season Picker

    private var seasonPill: some View {
        HStack {
            if seasons.isEmpty {
                Text("All matches")
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
        .background(Capsule().fill(GoStatsTheme.surface))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Record Hero

    private var recordCard: some View {
        GoStatsTheme.card {
            VStack(spacing: 14) {
                HStack(spacing: 0) {
                    recordColumn("\(wins)", label: "Wins")
                    divider
                    recordColumn("\(draws)", label: "Draws")
                    divider
                    recordColumn("\(losses)", label: "Losses")
                }

                Rectangle().fill(GoStatsTheme.divider).frame(height: 0.5)

                HStack {
                    Text("Win rate")
                        .font(.system(size: 13))
                        .foregroundStyle(GoStatsTheme.textMuted)
                    Spacer()
                    Text("\(winPct)%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                }
            }
        }
    }

    private func recordColumn(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GoStatsTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(GoStatsTheme.divider).frame(width: 1, height: 44)
    }

    // MARK: - Summary Grid

    private var summaryGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                summaryCard(value: "\(matches.count)", label: "Matches")
                summaryCard(value: "\(totalGF)", label: "Goals For")
                summaryCard(value: "\(totalGA)", label: "Goals Against")
            }
            HStack(spacing: 10) {
                summaryCard(value: goalDiff >= 0 ? "+\(goalDiff)" : "\(goalDiff)", label: "Goal Diff")
                summaryCard(value: "\(cleanSheets)", label: "Clean Sheets")
                summaryCard(value: String(format: "%.1f", avgGoalsFor), label: "Avg For")
            }
        }
    }

    private func summaryCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(GoStatsTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor,
                        radius: GoStatsTheme.cardShadowRadius,
                        x: 0, y: GoStatsTheme.cardShadowY)
        )
    }

    // MARK: - Recent Form

    private var formCard: some View {
        // `matches` is newest-first; show oldest→newest left-to-right for a natural timeline.
        let recent = Array(matches.prefix(5)).reversed()
        return GoStatsTheme.card {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader("RECENT FORM")
                HStack(spacing: 8) {
                    ForEach(Array(recent.enumerated()), id: \.offset) { _, match in
                        let r = formResult(for: match)
                        Text(r.letter)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(r.color))
                    }
                    Spacer()
                }
            }
        }
    }

    private func formResult(for match: MatchRecord) -> (letter: String, color: Color) {
        if match.goalsFor > match.goalsAgainst {
            return ("W", GoStatsTheme.ringGoals)
        } else if match.goalsFor < match.goalsAgainst {
            return ("L", GoStatsTheme.ringConceded)
        } else {
            return ("D", GoStatsTheme.textMuted)
        }
    }

    // MARK: - Leaderboard

    private func leaderboardCard(title: String,
                                 rows: [(player: Player, value: Int)],
                                 unit: String,
                                 emptyText: String) -> some View {
        GoStatsTheme.card {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader(title)

                if rows.isEmpty {
                    Text(emptyText)
                        .font(.system(size: 13))
                        .foregroundStyle(GoStatsTheme.emptyStateColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.prefix(5).enumerated()), id: \.offset) { index, entry in
                            if index > 0 {
                                Rectangle().fill(GoStatsTheme.divider).frame(height: 0.5)
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
                                Text("\(entry.value) \(unit)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Goalkeeper

    private var goalkeeperCard: some View {
        GoStatsTheme.card {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader("GOALKEEPING")
                statRow(label: "Save percentage", value: "\(gkSavePct)%")
                Rectangle().fill(GoStatsTheme.divider).frame(height: 0.5)
                statRow(label: "Clean sheets", value: "\(cleanSheets)")
                Rectangle().fill(GoStatsTheme.divider).frame(height: 0.5)
                statRow(label: "Goals conceded / game", value: String(format: "%.1f", avgGoalsAgainst))
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GoStatsTheme.card {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(GoStatsTheme.emptyStateColor)
                Text("No matches recorded for this season yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(GoStatsTheme.emptyStateColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}
