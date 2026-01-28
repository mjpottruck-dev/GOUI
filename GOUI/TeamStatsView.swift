import SwiftUI

struct TeamStatsView: View {
    let team: Team

    @State private var range: StatsDateRange = .allTime
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()

    private struct Row: Identifiable {
        let id: UUID
        let number: Int
        let name: String

        // ✅ Store as String for display
        let position: String

        let matchesPlayed: Int
        let minutesPlayed: Int

        let goals: Int
        let assists: Int
        let shots: Int
        let shotsOnTarget: Int

        let yellowCards: Int
        let redCards: Int

        let saves: Int
        let goalsConceded: Int

        let pkFaced: Int
        let pkSaved: Int
        let pkConceded: Int

        let impactScore: Int
    }

    private var filteredMatches: [MatchRecord] {
        team.matches.filter { m in
            range.matches(date: m.date, customStart: customStart, customEnd: endOfDay(customEnd))
        }
    }

    private var rows: [Row] {
        let matches = filteredMatches

        var secondsByPlayer: [UUID: Int] = [:]
        var matchesCountByPlayer: [UUID: Int] = [:]

        var goalsByPlayer: [UUID: Int] = [:]
        var assistsByPlayer: [UUID: Int] = [:]
        var shotsByPlayer: [UUID: Int] = [:]
        var sotByPlayer: [UUID: Int] = [:]

        var yellowsByPlayer: [UUID: Int] = [:]
        var redsByPlayer: [UUID: Int] = [:]

        var savesByPlayer: [UUID: Int] = [:]
        var concededByPlayer: [UUID: Int] = [:]

        var pkFacedByPlayer: [UUID: Int] = [:]
        var pkSavedByPlayer: [UUID: Int] = [:]
        var pkConcededByPlayer: [UUID: Int] = [:]

        for match in matches {
            for (pid, secs) in match.playerSeconds {
                secondsByPlayer[pid, default: 0] += secs
                if secs > 0 { matchesCountByPlayer[pid, default: 0] += 1 }
            }

            for (pid, stat) in match.playerStats {
                goalsByPlayer[pid, default: 0] += stat.goals
                assistsByPlayer[pid, default: 0] += stat.assists
                shotsByPlayer[pid, default: 0] += stat.shots
                sotByPlayer[pid, default: 0] += stat.shotsOnTarget

                yellowsByPlayer[pid, default: 0] += stat.yellowCards
                redsByPlayer[pid, default: 0] += stat.redCards

                savesByPlayer[pid, default: 0] += stat.saves
                concededByPlayer[pid, default: 0] += stat.goalsConceded

                pkFacedByPlayer[pid, default: 0] += stat.pkFaced
                pkSavedByPlayer[pid, default: 0] += stat.pkSaved
                pkConcededByPlayer[pid, default: 0] += stat.pkConceded
            }
        }

        return team.players.map { p in
            let secs = secondsByPlayer[p.id, default: 0]
            let mins = secs / 60
            let mp = matchesCountByPlayer[p.id, default: 0]

            let g = goalsByPlayer[p.id, default: 0]
            let a = assistsByPlayer[p.id, default: 0]
            let sh = shotsByPlayer[p.id, default: 0]
            let sot = sotByPlayer[p.id, default: 0]

            let yc = yellowsByPlayer[p.id, default: 0]
            let rc = redsByPlayer[p.id, default: 0]

            let sv = savesByPlayer[p.id, default: 0]
            let gc = concededByPlayer[p.id, default: 0]

            let pkF = pkFacedByPlayer[p.id, default: 0]
            let pkS = pkSavedByPlayer[p.id, default: 0]
            let pkC = pkConcededByPlayer[p.id, default: 0]

            let score =
                (g * 6) +
                (a * 4) +
                (sot * 2) +
                (sh * 1) +
                (sv * 2) +
                (pkS * 3) -
                (yc * 1) -
                (rc * 3) -
                (gc * 2) -
                (pkC * 2)

            return Row(
                id: p.id,
                number: p.number,
                name: p.name,
                position: p.position.rawValue,   // ✅ FIX HERE
                matchesPlayed: mp,
                minutesPlayed: mins,
                goals: g,
                assists: a,
                shots: sh,
                shotsOnTarget: sot,
                yellowCards: yc,
                redCards: rc,
                saves: sv,
                goalsConceded: gc,
                pkFaced: pkF,
                pkSaved: pkS,
                pkConceded: pkC,
                impactScore: score
            )
        }
    }

    private var teamSummary: (wins: Int, losses: Int, ties: Int, gf: Int, ga: Int) {
        var wins = 0, losses = 0, ties = 0, gf = 0, ga = 0
        for m in filteredMatches {
            gf += m.goalsFor
            ga += m.goalsAgainst
            if m.goalsFor > m.goalsAgainst { wins += 1 }
            else if m.goalsFor < m.goalsAgainst { losses += 1 }
            else { ties += 1 }
        }
        return (wins, losses, ties, gf, ga)
    }

    var body: some View {
        let r = rows
        let s = teamSummary

        List {
            Section("Filter") {
                Picker("Range", selection: $range) {
                    ForEach(StatsDateRange.allCases) { rr in
                        Text(rr.rawValue).tag(rr)
                    }
                }

                if range == .custom {
                    DatePicker("Start", selection: $customStart, displayedComponents: [.date])
                    DatePicker("End", selection: $customEnd, displayedComponents: [.date])
                }

                Text("Matches in range: \(filteredMatches.count)")
                    .foregroundStyle(.secondary)
            }

            Section("Team Summary") {
                statLine("Record", "\(s.wins)-\(s.losses)-\(s.ties)")
                statLine("Goals For / Against", "\(s.gf) / \(s.ga)")
            }

            Section("Leaders") {
                leaderLine("Goals", r) { $0.goals }
                leaderLine("Assists", r) { $0.assists }
                leaderLine("Shots", r) { $0.shots }
                leaderLine("Shots on Target", r) { $0.shotsOnTarget }
                leaderLine("Minutes Played", r) { $0.minutesPlayed }
                leaderLine("Saves", r) { $0.saves }
                leaderLine("Impact Score", r) { $0.impactScore }
            }

            Section("All Players") {
                ForEach(r.sorted(by: { $0.impactScore > $1.impactScore })) { p in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(p.number) • \(p.name) (\(p.position))")
                            .font(.headline)

                        Text("MP \(p.matchesPlayed) • Min \(p.minutesPlayed)")
                            .foregroundStyle(.secondary)

                        Text("G \(p.goals) • A \(p.assists) • Sh \(p.shots) • SOT \(p.shotsOnTarget)")
                            .foregroundStyle(.secondary)

                        let hasGK = (p.saves + p.goalsConceded + p.pkFaced + p.pkSaved + p.pkConceded) > 0
                        if hasGK {
                            Text("GK: Saves \(p.saves) • Conceded \(p.goalsConceded) • PK \(p.pkSaved)/\(p.pkFaced)")
                                .foregroundStyle(.secondary)
                        }

                        if p.yellowCards > 0 || p.redCards > 0 {
                            Text("Cards: YC \(p.yellowCards) • RC \(p.redCards)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Team Stats")
    }

    // MARK: - Helpers

    private func statLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func leaderLine(_ title: String, _ rows: [Row], value: (Row) -> Int) -> some View {
        let best = rows.max(by: { value($0) < value($1) })
        let v = best.map(value) ?? 0

        return HStack {
            Text(title)
            Spacer()
            if let best = best, v > 0 {
                Text("\(best.number) • \(best.name) — \(v)")
                    .foregroundStyle(.secondary)
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
    }

    private func endOfDay(_ date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}

