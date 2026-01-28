import SwiftUI

struct TeamArchiveView: View {

    var teamStore: TeamStore
    let teamID: UUID

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
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

                    if team.matches.isEmpty {
                        Text("No saved matches yet.")
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(team.matches) { match in
                            NavigationLink {
                                MatchDetailView(match: match, team: team)
                            } label: {
                                archiveRow(match)
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
                Text(match.opponent.isEmpty ? "Opponent" : match.opponent)
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
}
