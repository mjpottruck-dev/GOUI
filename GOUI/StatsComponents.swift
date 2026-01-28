import SwiftUI

struct StatsSummaryCard: View {
    let matches: [MatchRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary").font(.headline)
            Text("Filtered matches: \(matches.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
    }
}

struct StatsLeaderboards: View {
    let matches: [MatchRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Leaderboards").font(.headline)
            Text("Next step: build goals/assists/saves leaderboards from MatchRecord.playerStats.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
    }
}

