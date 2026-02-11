import SwiftUI

struct TeamStatsView: View {
    let team: Team

    @State private var range: StatsDateRange = .allTime
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()
    @State private var searchText: String = ""
    @State private var sortOrder: PlayerSort = .position
    @State private var rosterFilter: RosterFilter = .all
    @FocusState private var isSearchFocused: Bool

    private struct Row: Identifiable {
        let id: UUID
        let number: Int
        let name: String

        let position: Position

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

    private enum PlayerSort: String, CaseIterable, Identifiable {
        case position = "Position (Def → Off)"
        case nameAZ = "Name (A–Z)"
        case nameZA = "Name (Z–A)"

        var id: String { rawValue }
    }

    private enum RosterFilter: Hashable {
        case all
        case starters
        case goalies
    }

    private static let positionOrder: [Position] = [
        .gk,
        .cb, .lb, .rb, .lwb, .rwb, .def,
        .cdm, .dm, .cm, .cam, .am, .lm, .rm, .mid,
        .lw, .rw, .st, .cf, .fw
    ]

    private var positionIndex: [Position: Int] {
        Dictionary(uniqueKeysWithValues: Self.positionOrder.enumerated().map { ($0.element, $0.offset) })
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
                position: p.position,
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

    private var filteredRows: [Row] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let starters = Set(team.startingOnFieldIDs)
        return rows.filter { row in
            let matchesSearch = trimmed.isEmpty || row.name.localizedCaseInsensitiveContains(trimmed)
            guard matchesSearch else { return false }
            switch rosterFilter {
            case .all:
                return true
            case .starters:
                return starters.contains(row.id)
            case .goalies:
                return row.position == .gk
            }
        }
    }

    private var sortedRows: [Row] {
        switch sortOrder {
        case .position:
            return filteredRows.sorted { lhs, rhs in
                let leftIndex = positionIndex[lhs.position] ?? Int.max
                let rightIndex = positionIndex[rhs.position] ?? Int.max
                if leftIndex != rightIndex {
                    return leftIndex < rightIndex
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        case .nameAZ:
            return filteredRows.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .nameZA:
            return filteredRows.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending
            }
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

        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    GlassCard(level: .surface) {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Range", selection: $range) {
                                ForEach(StatsDateRange.allCases) { rr in
                                    Text(rr.rawValue).tag(rr)
                                }
                            }
                            .pickerStyle(.menu)

                            if range == .custom {
                                DatePicker("Start", selection: $customStart, displayedComponents: [.date])
                                DatePicker("End", selection: $customEnd, displayedComponents: [.date])
                            }

                            Picker("Roster Filter", selection: $rosterFilter) {
                                Text("All").tag(RosterFilter.all)
                                Text("Starters").tag(RosterFilter.starters)
                                Text("Goalies").tag(RosterFilter.goalies)
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: 10) {
                                Button { isSearchFocused = true } label: {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)

                                TextField("Search player", text: $searchText)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($isSearchFocused)

                                if !searchText.isEmpty {
                                    Button { searchText = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Picker("Sort", selection: $sortOrder) {
                                ForEach(PlayerSort.allCases) { sort in
                                    Text(sort.rawValue).tag(sort)
                                }
                            }
                            .pickerStyle(.menu)

                            Text("Matches in range: \(filteredMatches.count)")
                                .font(.footnote)
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }

                    GlassCard(level: .surface) {
                        VStack(alignment: .leading, spacing: 6) {
                            statLine("Record", "\(s.wins)-\(s.losses)-\(s.ties)")
                            statLine("Goals For / Against", "\(s.gf) / \(s.ga)")
                        }
                    }

                    GlassCard(level: .surface) {
                        VStack(alignment: .leading, spacing: 6) {
                            leaderLine("Goals", r) { $0.goals }
                            leaderLine("Assists", r) { $0.assists }
                            leaderLine("Shots", r) { $0.shots }
                            leaderLine("Shots on Target", r) { $0.shotsOnTarget }
                        }
                    }

                    ForEach(sortedRows) { row in
                        GlassCard(level: .surface) {
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(row.number)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(GoStatsTheme.primary))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(row.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                    Text(row.position.rawValue)
                                        .font(.subheadline)
                                        .foregroundStyle(GoStatsTheme.text2)

                                    FlowLayout(spacing: 6) {
                                        statPill("MP", row.matchesPlayed)
                                        statPill("Min", row.minutesPlayed)
                                        statPill("G", row.goals)
                                        statPill("A", row.assists)
                                        statPill("Sh", row.shots)
                                        statPill("SOT", row.shotsOnTarget)
                                        statPill("Sv", row.saves)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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

    @ViewBuilder
    private func statPill(_ label: String, _ value: Int) -> some View {
        if value > 0 {
            Text("\(label) \(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GoStatsTheme.text)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.75)))
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: min(width, x), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
