import SwiftUI

struct TeamArchiveView: View {

    var teamStore: TeamStore
    let teamID: UUID

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var seasons: [Season] {
        teamStore.seasons(for: teamID)
    }

    private var activeSeasonID: UUID? {
        teamStore.activeSeasonID(for: teamID)
    }

    private var filteredMatches: [MatchRecord] {
        guard let team else { return [] }
        guard let activeSeasonID else { return team.matches }
        return team.matches.filter { $0.seasonID == activeSeasonID }
    }

    private var groupedMatches: [(month: Date, matches: [MatchRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMatches) { match -> Date in
            let components = calendar.dateComponents([.year, .month], from: match.date)
            return calendar.date(from: components) ?? match.date
        }
        return grouped
            .map { (month: $0.key, matches: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            if let team {
                List {
                    // Header row (no Section)
                    Text("ARCHIVE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)

                    if !seasons.isEmpty {
                        Picker("Season", selection: Binding(
                            get: { activeSeasonID ?? seasons.first?.id },
                            set: { newValue in
                                if let newValue {
                                    teamStore.setActiveSeason(newValue, for: teamID)
                                }
                            }
                        )) {
                            ForEach(seasons) { season in
                                Text(season.name).tag(Optional(season.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Color.clear)
                    }

                    if filteredMatches.isEmpty {
                        Text("No saved matches yet.")
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(groupedMatches, id: \.month) { group in
                            Section(group.month.formatted(.dateTime.month(.wide).year())) {
                                ForEach(group.matches) { match in
                                    NavigationLink {
                                        MatchDetailView(match: match, team: team, sport: SportCatalog.sport(for: team.sportID))
                                    } label: {
                                        archiveRow(match)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)

            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("Team not found.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Create a team first.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func archiveRow(_ match: MatchRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(primaryMatchLabel(match))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(match.goalsFor)–\(match.goalsAgainst)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
    }

    private func primaryMatchLabel(_ match: MatchRecord) -> String {
        if !match.opponent.isEmpty {
            return match.opponent
        }
        if !match.title.isEmpty {
            return match.title
        }
        return "Meet"
    }
}
