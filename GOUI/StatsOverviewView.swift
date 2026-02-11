import SwiftUI

struct StatsOverviewView: View {

    @State var teamStore: TeamStore
    let teamID: UUID

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
                    metricChip("GF", "\(totals.goalsFor)")
                    metricChip("GA", "\(totals.goalsAgainst)")
                    metricChip("GD", "\(totals.goalDiff)")
                }

                HStack(spacing: 10) {
                    metricChip("Shots", "\(totals.shots)")
                    metricChip("SOT", "\(totals.shotsOnTarget)")
                    metricChip("Conv", totals.conversionText)
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
                        leaderRow(title: "Goals", icon: "soccerball", items: leaders.goals)
                        leaderRow(title: "Assists", icon: "arrowshape.turn.up.right.fill", items: leaders.assists)
                        leaderRow(title: "Shots", icon: "scope", items: leaders.shots)
                        leaderRow(title: "Saves", icon: "hand.raised.fill", items: leaders.saves)
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
                                MatchDetailView(match: m, team: team ?? Team(name: "Team"))
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
        var shots = 0, sot = 0

        for m in team.matches {
            gf += m.goalsFor
            ga += m.goalsAgainst

            for (_, line) in m.playerStats {
                shots += line.shots
                sot += line.shotsOnTarget
            }
        }

        return Totals(goalsFor: gf, goalsAgainst: ga, shots: shots, shotsOnTarget: sot)
    }

    private var leaders: Leaders {
        guard let team else { return Leaders() }

        var agg: [UUID: PlayerStatLine] = [:]

        for m in team.matches {
            for (pid, line) in m.playerStats {
                var cur = agg[pid] ?? PlayerStatLine()
                cur.goals += line.goals
                cur.assists += line.assists
                cur.shots += line.shots
                cur.shotsOnTarget += line.shotsOnTarget
                cur.saves += line.saves
                agg[pid] = cur
            }
        }

        func top(_ key: KeyPath<PlayerStatLine, Int>) -> [(String, Int)] {
            let pairs: [(String, Int)] = agg.compactMap { pid, line in
                let value = line[keyPath: key]
                guard value > 0 else { return nil }
                let name = team.players.first(where: { $0.id == pid }).map { "#\($0.number) \($0.name)" } ?? "Player"
                return (name, value)
            }
            return pairs.sorted { $0.1 > $1.1 }
        }

        return Leaders(
            goals: top(\.goals),
            assists: top(\.assists),
            shots: top(\.shots),
            saves: top(\.saves)
        )
    }
}

private struct Totals {
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0
    var shots: Int = 0
    var shotsOnTarget: Int = 0

    var goalDiff: Int { goalsFor - goalsAgainst }

    var conversionText: String {
        let denom = max(shots, 1)
        let pct = Double(goalsFor) / Double(denom) * 100.0
        return String(format: "%.0f%%", pct)
    }
}

private struct Leaders {
    var goals: [(name: String, value: Int)] = []
    var assists: [(name: String, value: Int)] = []
    var shots: [(name: String, value: Int)] = []
    var saves: [(name: String, value: Int)] = []

    var hasAnyData: Bool {
        !goals.isEmpty || !assists.isEmpty || !shots.isEmpty || !saves.isEmpty
    }
}

