import SwiftUI

struct StatsOverviewView: View {

    @State var teamStore: TeamStore
    let teamID: UUID
    let sport: any SportDefinition

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    topSummary
                    leadersCard
                    recentMatchesCard
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
    }

    private var topSummary: some View {
        LiquidGlassContainer(material: .thinMaterial) {
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("OVERVIEW")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)

                    Spacer()

                    Text("\(team?.matches.count ?? 0) matches")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                HStack(spacing: 10) {
                    metricChip("For", "\(totals.goalsFor)")
                    metricChip("Against", "\(totals.goalsAgainst)")
                    metricChip("Diff", "\(totals.goalDiff)")
                }

                HStack(spacing: 10) {
                    ForEach(teamSummaryStats, id: \.id) { stat in
                        metricChip(stat.shortLabel ?? stat.displayName, "\(totals.statValues[stat.id, default: 0])")
                    }
                    if let conversionText = totals.conversionText {
                        metricChip("Conv", conversionText)
                    }
                }
            }
        }
    }

    private var leadersCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {

                Text("LEADERS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                if !leaders.hasAnyData {
                    emptyRow(icon: "crown", text: "No stats yet. Save a match to generate leaders.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(leaders.entries, id: \.stat.id) { entry in
                            leaderRow(title: entry.stat.displayName, icon: entry.iconName, items: entry.items)
                        }
                    }
                }
            }
        }
    }

    private var recentMatchesCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("RECENT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)

                    Spacer()

                    if let count = team?.matches.count, count > 0 {
                        Text("Last \(min(count, 5))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                if let matches = team?.matches, !matches.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(matches.prefix(5)) { m in
                            NavigationLink {
                                MatchDetailView(match: m, team: team ?? Team(name: "Team"), sport: sport)
                            } label: {
                                recentRow(m)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    emptyRow(icon: "tray", text: "No saved matches yet.")
                }
            }
        }
    }

    private func metricChip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
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

    private func emptyRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
        }
        .padding(.vertical, 6)
    }

    private func leaderRow(title: String, icon: String, items: [(name: String, value: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.teal)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                Spacer()
            }

            if items.isEmpty {
                Text("—")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text)

                            Spacer()

                            Text("\(item.value)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(GoStatsTheme.text2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.50))
        )
    }

    private func recentRow(_ match: MatchRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.opponent.isEmpty ? "Opponent" : match.opponent)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }

            Spacer()

            Text("\(match.goalsFor)–\(match.goalsAgainst)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.50))
        )
    }

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var totals: Totals {
        guard let team else { return Totals() }

        var gf = 0, ga = 0
        var statValues: [String: Int] = [:]

        for m in team.matches {
            gf += m.goalsFor
            ga += m.goalsAgainst

            for (_, line) in m.playerStats {
                for stat in teamSummaryStats {
                    statValues[stat.id, default: 0] += line.value(for: stat.id)
                }
            }
        }

        return Totals(goalsFor: gf, goalsAgainst: ga, statValues: statValues, conversionText: conversionText(for: statValues, goalsFor: gf))
    }

    private var leaders: Leaders {
        guard let team else { return Leaders() }

        var totalsByPlayer: [UUID: [String: Int]] = [:]

        for m in team.matches {
            for (pid, line) in m.playerStats {
                for stat in leaderStatTypes {
                    totalsByPlayer[pid, default: [:]][stat.id, default: 0] += line.value(for: stat.id)
                }
            }
        }

        func top(stat: StatType) -> [(String, Int)] {
            let pairs: [(String, Int)] = totalsByPlayer.compactMap { pid, statTotals in
                let value = statTotals[stat.id, default: 0]
                guard value > 0 else { return nil }
                let name = team.players.first(where: { $0.id == pid }).map { "#\($0.number) \($0.name)" } ?? "Player"
                return (name, value)
            }
            return pairs.sorted { $0.1 > $1.1 }
        }

        let entries = leaderStatTypes.map { stat in
            Leaders.Entry(stat: stat, items: top(stat: stat))
        }
        return Leaders(entries: entries)
    }

    private var teamSummaryStats: [StatType] {
        let stats = sport.statSchema.filter { $0.countsForTeam }
        let preferred = ["shots", "shotsOnTarget"].compactMap { id in
            stats.first(where: { $0.id == id })
        }
        if !preferred.isEmpty {
            return preferred
        }
        return Array(stats.prefix(2))
    }

    private var leaderStatTypes: [StatType] {
        Array(sport.statSchema.filter { $0.countsForPlayer }.prefix(4))
    }

    private func conversionText(for statValues: [String: Int], goalsFor: Int) -> String? {
        let shots = statValues["shots", default: 0]
        guard shots > 0 else { return nil }
        let pct = Double(goalsFor) / Double(shots) * 100.0
        return String(format: "%.0f%%", pct)
    }
}

private struct Totals {
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0
    var statValues: [String: Int] = [:]
    var conversionText: String? = nil

    var goalDiff: Int { goalsFor - goalsAgainst }
}

private struct Leaders {
    struct Entry {
        let stat: StatType
        let items: [(name: String, value: Int)]

        var iconName: String {
            switch stat.id {
            case "goals":
                return "soccerball"
            case "assists":
                return "arrowshape.turn.up.right.fill"
            case "shots":
                return "scope"
            case "saves":
                return "hand.raised.fill"
            default:
                return "chart.bar.fill"
            }
        }
    }

    var entries: [Entry] = []

    var hasAnyData: Bool {
        entries.contains { !$0.items.isEmpty }
    }
}
