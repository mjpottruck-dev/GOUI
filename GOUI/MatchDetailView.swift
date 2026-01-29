import SwiftUI

struct MatchDetailView: View {
    let match: MatchRecord
    let team: Team
    @State private var selectedPlayerDetail: PlayerDetail? = nil

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    LiquidGlassContainer(material: .thinMaterial) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(match.opponent.isEmpty ? "Opponent" : match.opponent)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)

                                    Text(match.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }

                                Spacer()

                                Text("\(match.goalsFor)–\(match.goalsAgainst)")
                                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(GoStatsTheme.text)
                            }

                            HStack(spacing: 10) {
                                chip("Time", secondsToTime(match.secondsElapsed))
                                chip("Field", "\(match.fieldSize)v\(match.fieldSize)")
                            }

                            if !match.title.isEmpty || !match.notes.isEmpty {
                                Divider().opacity(0.55)
                                if !match.title.isEmpty {
                                    Text(match.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                }
                                if !match.notes.isEmpty {
                                    Text(match.notes)
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PLAYER STATS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.primary)

                            VStack(spacing: 10) {
                                ForEach(sortedPlayersForMatch, id: \.id) { p in
                                    playerRow(
                                        player: p,
                                        line: match.playerStats[p.id] ?? PlayerStatLine(),
                                        seconds: match.playerSeconds[p.id] ?? 0
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPlayerDetail) { detail in
            NavigationStack {
                ZStack {
                    GoStatsTheme.bg.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 12) {
                            LiquidGlassContainer(cornerRadius: 22) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PLAYER")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.primary)

                                    Text("#\(detail.player.number) \(detail.player.name)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)

                                    Text("\(detail.player.position.rawValue) • \(secondsToTime(detail.seconds))")
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }

                            LiquidGlassContainer(cornerRadius: 22) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("MATCH STATS")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.primary)

                                    VStack(spacing: 8) {
                                        statsRow("Goals", detail.line.goals)
                                        statsRow("Assists", detail.line.assists)
                                        statsRow("Shots", detail.line.shots)
                                        statsRow("Shots on Target", detail.line.shotsOnTarget)
                                        statsRow("Yellow Cards", detail.line.yellowCards)
                                        statsRow("Red Cards", detail.line.redCards)
                                        statsRow("Saves", detail.line.saves)
                                        statsRow("Goals Conceded", detail.line.goalsConceded)
                                        statsRow("PK Faced", detail.line.pkFaced)
                                        statsRow("PK Saved", detail.line.pkSaved)
                                        statsRow("PK Conceded", detail.line.pkConceded)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Player Stats")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var sortedPlayersForMatch: [Player] {
        let appearedIDs = Set(match.playerSeconds.keys)
        let appeared = team.players.filter { appearedIDs.contains($0.id) }
        return appeared.sorted { ($0.number, $0.name) < ($1.number, $1.name) }
    }

    private func playerRow(player: Player, line: PlayerStatLine, seconds: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("#\(player.number) \(player.name)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                Text("\(player.position.rawValue) • \(secondsToTime(seconds))")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }

            Spacer()

            HStack(spacing: 10) {
                statPill("G", "\(line.goals)")
                statPill("A", "\(line.assists)")
                statPill("S", "\(line.shots)")
                statPill("SOT", "\(line.shotsOnTarget)")
                statsActionButton {
                    selectedPlayerDetail = PlayerDetail(player: player, line: line, seconds: seconds)
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

    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private func statsActionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.primary)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View all stats")
    }

    private func chip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func secondsToTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }

    private func statsRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
            Spacer()
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text2)
        }
    }

    private struct PlayerDetail: Identifiable {
        let id: UUID
        let player: Player
        let line: PlayerStatLine
        let seconds: Int

        init(player: Player, line: PlayerStatLine, seconds: Int) {
            self.id = player.id
            self.player = player
            self.line = line
            self.seconds = seconds
        }
    }
}
