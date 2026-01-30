import SwiftUI

struct AdvancedAnalyticsDashboardView: View {
    let team: Team
    let sport: any SportDefinition
    let matches: [MatchRecord]
    let seasons: [Season]

    private var teamMetrics: [AnalyticsMetricResult] {
        let context = AnalyticsContext(team: team, sport: sport, matches: matches, seasons: seasons)
        return AnalyticsEngine.shared.metrics(for: sport.id).map { $0.compute(context: context) }
    }

    var body: some View {
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
