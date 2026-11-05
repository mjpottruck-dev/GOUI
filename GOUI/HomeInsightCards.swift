import SwiftUI

/// Cards under the main home buttons: last match + recent form, top scorers,
/// and playing-time balance. Built only from saved matches (no network).
struct HomeInsightCards: View {
    let team: Team
    let teamStore: TeamStore

    // MARK: - Data

    /// Matches in the active season (falls back to all matches if none are tagged).
    private var seasonMatches: [MatchRecord] {
        let all = team.matches.sorted { $0.date > $1.date }
        guard let season = teamStore.activeSeasonID else { return all }
        let inSeason = all.filter { $0.seasonID == season }
        return inSeason.isEmpty ? all : inSeason
    }

    private var lastMatch: MatchRecord? { seasonMatches.first }

    private var recentForm: [MatchRecord] { Array(seasonMatches.prefix(5)) }

    private struct Leader: Identifiable {
        let id: UUID
        let player: Player
        let goals: Int
        let assists: Int
    }

    private var topScorers: [Leader] {
        var goals: [UUID: Int] = [:]
        var assists: [UUID: Int] = [:]
        for m in seasonMatches {
            for (pid, line) in m.playerStats {
                goals[pid, default: 0] += line.goals
                assists[pid, default: 0] += line.assists
            }
        }
        return team.players
            .map { Leader(id: $0.id, player: $0, goals: goals[$0.id] ?? 0, assists: assists[$0.id] ?? 0) }
            .filter { $0.goals + $0.assists > 0 }
            .sorted { ($0.goals, $0.assists) > ($1.goals, $1.assists) }
            .prefix(3)
            .map { $0 }
    }

    private struct Minutes: Identifiable {
        let id: UUID
        let player: Player
        let minutes: Int
    }

    /// Every rostered player's season minutes, lowest first.
    private var minutesByPlayer: [Minutes] {
        var seconds: [UUID: Int] = [:]
        for m in seasonMatches {
            for (pid, s) in m.playerSeconds { seconds[pid, default: 0] += s }
        }
        return team.players
            .map { Minutes(id: $0.id, player: $0, minutes: (seconds[$0.id] ?? 0) / 60) }
            .sorted { $0.minutes < $1.minutes }
    }

    private var averageMinutes: Int {
        let all = minutesByPlayer
        guard !all.isEmpty else { return 0 }
        return all.reduce(0) { $0 + $1.minutes } / all.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: GoStatsTheme.cardGap) {
            if let last = lastMatch {
                lastMatchCard(last)
                if !topScorers.isEmpty { topScorersCard }
                if !team.players.isEmpty { playingTimeCard }
            } else {
                emptyCard
            }
        }
    }

    // MARK: - Cards

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("YOUR SEASON")
            Text("No matches yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text("Tap Start Match to record your first game. Your last result, top scorers and playing time will show up here.")
                .font(.system(size: 14))
                .foregroundStyle(GoStatsTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .homeCard()
    }

    private func lastMatchCard(_ match: MatchRecord) -> some View {
        NavigationLink {
            MatchGameDetailView(match: match, team: team, teamStore: teamStore)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    label("LAST MATCH")
                    Spacer()
                    Text(match.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.textMuted)
                }
                HStack(alignment: .center, spacing: 12) {
                    resultChip(match, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("vs \(match.opponent.isEmpty ? "Opponent" : match.opponent)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                            .lineLimit(1)
                        if let scorers = scorerLine(match) {
                            Text(scorers)
                                .font(.system(size: 13))
                                .foregroundStyle(GoStatsTheme.textMuted)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text("\(match.goalsFor) – \(match.goalsAgainst)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .monospacedDigit()
                }
                if recentForm.count > 1 {
                    HStack(spacing: 6) {
                        Text("Form")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(GoStatsTheme.textMuted)
                            .padding(.trailing, 4)
                        // Oldest → newest, left to right
                        ForEach(Array(recentForm.reversed())) { m in
                            resultChip(m, size: 22)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    }
                }
            }
            .homeCard()
        }
        .buttonStyle(.plain)
    }

    private var topScorersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("TOP SCORERS")
            ForEach(Array(topScorers.enumerated()), id: \.element.id) { rank, leader in
                HStack(spacing: 12) {
                    Text("\(rank + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(rank == 0 ? .white : GoStatsTheme.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(rank == 0 ? GoStatsTheme.textPrimary : GoStatsTheme.surface))
                    Text("#\(leader.player.number) \(leader.player.name)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(leader.goals) G")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .monospacedDigit()
                    Text("\(leader.assists) A")
                        .font(.system(size: 15))
                        .foregroundStyle(GoStatsTheme.textMuted)
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .homeCard()
    }

    private var playingTimeCard: some View {
        let lowest = Array(minutesByPlayer.prefix(3))
        let maxMinutes = max(minutesByPlayer.last?.minutes ?? 0, 1)
        let avg = averageMinutes
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                label("PLAYING TIME")
                Spacer()
                Text("Team avg \(avg) min")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.textMuted)
            }
            Text("Fewest minutes this season")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            ForEach(lowest) { row in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("#\(row.player.number) \(row.player.name)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(row.minutes) min")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(row.minutes < avg / 2 ? GoStatsTheme.accent : GoStatsTheme.textPrimary)
                            .monospacedDigit()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(GoStatsTheme.ringTrack)
                            Capsule()
                                .fill(row.minutes < avg / 2 ? GoStatsTheme.accent : GoStatsTheme.textPrimary)
                                .frame(width: max(4, geo.size.width * CGFloat(row.minutes) / CGFloat(maxMinutes)))
                        }
                    }
                    .frame(height: 6)
                }
            }
            if let short = lowest.first, avg > 0, short.minutes < avg / 2 {
                Text("\(short.player.name) is well under the team average. Consider starting them next game.")
                    .font(.system(size: 13))
                    .foregroundStyle(GoStatsTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .homeCard()
    }

    // MARK: - Helpers

    private func resultChip(_ m: MatchRecord, size: CGFloat) -> some View {
        let (letter, color): (String, Color) = m.goalsFor > m.goalsAgainst
            ? ("W", GoStatsTheme.positive)
            : (m.goalsFor == m.goalsAgainst ? ("D", GoStatsTheme.controlGray) : ("L", GoStatsTheme.ringConceded))
        return Text(letter)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(color))
    }

    private func scorerLine(_ m: MatchRecord) -> String? {
        let names = team.players
            .compactMap { p -> String? in
                let g = m.playerStats[p.id]?.goals ?? 0
                guard g > 0 else { return nil }
                let first = p.name.split(separator: " ").first.map(String.init) ?? p.name
                return g > 1 ? "\(first) ×\(g)" : first
            }
        return names.isEmpty ? nil : "⚽ " + names.joined(separator: ", ")
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(1)
            .foregroundStyle(GoStatsTheme.sectionHeaderColor)
    }
}

private extension View {
    func homeCard() -> some View {
        padding(GoStatsTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
    }
}
