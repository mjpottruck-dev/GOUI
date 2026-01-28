import SwiftUI

struct TeamRosterView: View {
    @State private var teamStore = TeamStore()

    var body: some View {
        NavigationStack {
            List {
                ForEach(teamStore.teams) { team in
                    NavigationLink {
                        TeamDetailSimpleView(teamID: team.id, teamStore: teamStore)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(team.name).font(.headline)
                            Text("\(team.players.count) players • \(team.matches.count) matches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Team Roster")
        }
    }
}

private struct TeamDetailSimpleView: View {
    let teamID: UUID
    @State var teamStore: TeamStore

    @State private var editingTeam: Team? = nil

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        Group {
            if let team = team {
                List {
                    Section("Players") {
                        ForEach(team.players) { p in
                            HStack {
                                Text("#\(p.number) \(p.name)")
                                Spacer()
                                Text(p.position.rawValue)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section("Archive") {
                        if team.matches.isEmpty {
                            Text("No matches saved yet.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(team.matches) { m in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(m.goalsFor) - \(m.goalsAgainst) vs \(m.opponent)")
                                        .font(.headline)
                                    Text(m.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(team.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            editingTeam = team
                        }
                    }
                }
                .sheet(item: $editingTeam) { teamToEdit in
                    EditRosterView(team: teamToEdit) { updated in
                        // Preserve matches
                        var merged = updated
                        merged.matches = teamToEdit.matches
                        teamStore.updateTeam(merged)
                    }
                }

            } else {
                Text("Team not found.")
                    .foregroundColor(.secondary)
            }
        }
    }
}

