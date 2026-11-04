import SwiftUI

struct StatsSummaryCard: View {
    let matches: [MatchRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary").font(.custom("DM Sans", size: 17).weight(.medium))
            Text("Filtered matches: \(matches.count)")
                .font(.custom("DM Sans", size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
        )
        .padding(.horizontal, 16)
    }
}

struct StatsLeaderboards: View {
    let matches: [MatchRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Leaderboards").font(.custom("DM Sans", size: 17).weight(.medium))
            Text("Next step: build goals/assists/saves leaderboards from MatchRecord.playerStats.")
                .font(.custom("DM Sans", size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
        )
        .padding(.horizontal, 16)
    }
}

