import SwiftUI

struct AdvancedAnalyticsDashboardView: View {
    let team: Team
    let sport: any SportDefinition
    let matches: [MatchRecord]
    let seasons: [Season]
    let spotlightPlayer: Player?

    private var teamMetrics: [AnalyticsMetricResult] {
        let context = AnalyticsContext(team: team, sport: sport, matches: matches, seasons: seasons)
        return AnalyticsEngine.shared.metrics(for: sport.id).map { $0.compute(context: context) }
    }

    private var playerMetrics: [AnalyticsMetricResult] {
        guard let player = spotlightPlayer else { return [] }
        let context = AnalyticsContext(team: team, sport: sport, matches: matches, seasons: seasons, player: player)
        return AnalyticsEngine.shared.metrics(for: sport.id).map { $0.compute(context: context) }
    }

    var body: some View {
        VStack(spacing: 12) {
            LiquidGlassContainer(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ADVANCED ANALYTICS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.primary)

                    VStack(spacing: 10) {
                        ForEach(teamMetrics) { metric in
                            metricRow(metric)
                        }
                    }
                }
            }

            LiquidGlassContainer(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PLAYER SPOTLIGHT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.primary)

                    if let player = spotlightPlayer {
                        Text("#\(player.number) \(player.name)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)

                        VStack(spacing: 10) {
                            ForEach(playerMetrics) { metric in
                                metricRow(metric)
                            }
                        }
                    } else {
                        Text("Add player stats to unlock spotlight analytics.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }
            }
        }
    }

    private func metricRow(_ metric: AnalyticsMetricResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Spacer()
                Text(metric.value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GoStatsTheme.text)
            }

            Text(metric.detail)
                .font(.system(size: 12))
                .foregroundStyle(GoStatsTheme.text2)

            if let footnote = metric.footnote {
                Text(footnote)
                    .font(.system(size: 11))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }
}
