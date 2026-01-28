import SwiftUI

struct RosterHomeView: View {

    @Bindable var teamStore: TeamStore

    @State private var showingCreateTeam = false
    @State private var editingTeam: Team? = nil

    var body: some View {
        NavigationStack {
            List {
                if teamStore.teams.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Teams Yet")
                            .font(.headline)
                        Text("Tap + to create your first team.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(teamStore.teams) { team in
                        Button {
                            editingTeam = team
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team.name)
                                        .font(.headline)
                                    Text("\(team.players.count) players")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            let team = teamStore.teams[idx]
                            teamStore.deleteTeam(team)
                        }
                    }
                }
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateTeam = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTeam) {
                CreateTeamView(teamStore: teamStore) { _ in
                    // CreateTeamView already adds the team + dismisses.
                    showingCreateTeam = false
                }
            }
            .sheet(item: $editingTeam) { team in
                EditRosterView(team: team) { updated in
                    var merged = updated
                    if let current = teamStore.teams.first(where: { $0.id == team.id }) {
                        merged.matches = current.matches
                    }
                    teamStore.updateTeam(merged)
                }
            }
        }
    }
}

