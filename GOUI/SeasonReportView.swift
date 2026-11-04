import SwiftUI

struct SeasonReportView: View {
    let team: Team
    let insightText: String

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("Season Report")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Season record hero card
                    recordCard

                    // AI Insight
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(GoStatsTheme.textMuted)
                            Text("SEASON INSIGHT")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1)
                                .foregroundStyle(GoStatsTheme.textMuted)
                        }
                        Text(insightText)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "1a1a1a"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(GoStatsTheme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBg)

                    // Top scorers
                    topScorersCard

                    // GK stats
                    gkStatsCard

                    // Form guide
                    formGuideCard

                    // Share button
                    Button {
                        shareReport()
                    } label: {
                        Text("Share Report")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color(hex: "1a1a1a"))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Season Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Record Card

    private var recordCard: some View {
        let wins = team.matches.filter { $0.goalsFor > $0.goalsAgainst }.count
        let draws = team.matches.filter { $0.goalsFor == $0.goalsAgainst }.count
        let losses = team.matches.filter { $0.goalsFor < $0.goalsAgainst }.count

        return HStack(spacing: 0) {
            statColumn("\(wins)", label: "Wins")
            Rectangle().fill(GoStatsTheme.divider).frame(width: 1, height: 48)
            statColumn("\(draws)", label: "Draws")
            Rectangle().fill(GoStatsTheme.divider).frame(width: 1, height: 48)
            statColumn("\(losses)", label: "Losses")
        }
        .padding(.vertical, 16)
        .background(cardBg)
    }

    private func statColumn(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GoStatsTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Top Scorers

    private var topScorersCard: some View {
        let scorers = topScorers(limit: 3)
        return VStack(alignment: .leading, spacing: 10) {
            GoStatsTheme.sectionHeader("TOP SCORERS")

            if scorers.isEmpty {
                Text("No goals this season")
                    .font(.system(size: 13))
                    .foregroundStyle(GoStatsTheme.textMuted)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(scorers.enumerated()), id: \.offset) { idx, entry in
                    HStack {
                        Text("\(idx + 1)")
                            .font(.system(size: 13))
                            .foregroundStyle(GoStatsTheme.textMuted)
                            .frame(width: 20)
                        Text(entry.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                        Spacer()
                        Text("\(entry.goals) goals")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                    }
                }
            }
        }
        .padding(GoStatsTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
    }

    // MARK: - GK Stats

    private var gkStatsCard: some View {
        let gkStats = goalkeeperStats()
        return VStack(alignment: .leading, spacing: 10) {
            GoStatsTheme.sectionHeader("GOALKEEPER")

            HStack {
                Text("Save Percentage")
                    .font(.system(size: 14))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                Spacer()
                Text("\(gkStats.savePct)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
            }
            HStack {
                Text("Clean Sheets")
                    .font(.system(size: 14))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                Spacer()
                Text("\(gkStats.cleanSheets)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
            }
        }
        .padding(GoStatsTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
    }

    // MARK: - Form Guide

    private var formGuideCard: some View {
        let results = last5Results()
        return VStack(alignment: .leading, spacing: 10) {
            GoStatsTheme.sectionHeader("RECENT FORM")

            HStack(spacing: 8) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                    Text(result.letter)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(result.color))
                }
                Spacer()
            }
        }
        .padding(GoStatsTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
    }

    // MARK: - Helpers

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
            .fill(Color.white)
            .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
    }

    private struct ScorerEntry {
        let name: String
        let goals: Int
    }

    private func topScorers(limit: Int) -> [ScorerEntry] {
        var totals: [UUID: Int] = [:]
        for match in team.matches {
            for (pid, stat) in match.playerStats {
                totals[pid, default: 0] += stat.goals
            }
        }
        return totals
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { pid, goals -> ScorerEntry? in
                guard goals > 0, let p = team.players.first(where: { $0.id == pid }) else { return nil }
                return ScorerEntry(name: p.name, goals: goals)
            }
    }

    private struct GKStats {
        let savePct: Int
        let cleanSheets: Int
    }

    private func goalkeeperStats() -> GKStats {
        var totalSaves = 0, totalConceded = 0, cleanSheets = 0
        for match in team.matches {
            var matchConceded = 0
            for (pid, stat) in match.playerStats {
                if team.players.first(where: { $0.id == pid })?.position == .gk {
                    totalSaves += stat.saves
                    totalConceded += stat.goalsConceded
                    matchConceded += stat.goalsConceded
                }
            }
            if match.goalsAgainst == 0 { cleanSheets += 1 }
        }
        let total = totalSaves + totalConceded
        let pct = total > 0 ? Int(round(Double(totalSaves) / Double(total) * 100)) : 0
        return GKStats(savePct: pct, cleanSheets: cleanSheets)
    }

    private struct FormResult {
        let letter: String
        let color: Color
    }

    private func last5Results() -> [FormResult] {
        Array(team.matches.prefix(5)).map { m in
            if m.goalsFor > m.goalsAgainst {
                return FormResult(letter: "W", color: Color(hex: "22C55E"))
            } else if m.goalsFor < m.goalsAgainst {
                return FormResult(letter: "L", color: Color(hex: "EF4444"))
            } else {
                return FormResult(letter: "D", color: Color(hex: "aaaaaa"))
            }
        }
    }

    private func shareReport() {
        var text = "Season Report - \(team.name)\n\n"
        let wins = team.matches.filter { $0.goalsFor > $0.goalsAgainst }.count
        let draws = team.matches.filter { $0.goalsFor == $0.goalsAgainst }.count
        let losses = team.matches.filter { $0.goalsFor < $0.goalsAgainst }.count
        text += "Record: \(wins)W - \(draws)D - \(losses)L\n\n"
        text += insightText + "\n\n"

        let scorers = topScorers(limit: 3)
        if !scorers.isEmpty {
            text += "Top Scorers:\n"
            for (i, s) in scorers.enumerated() {
                text += "\(i+1). \(s.name) - \(s.goals) goals\n"
            }
        }

        let gk = goalkeeperStats()
        text += "\nGK Save %: \(gk.savePct)% | Clean Sheets: \(gk.cleanSheets)"

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            root.present(vc, animated: true)
        }
    }
}
