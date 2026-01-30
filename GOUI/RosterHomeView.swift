import SwiftUI

struct RosterHomeView: View {

    @Bindable var teamStore: TeamStore

    @State private var showingCreateTeam = false
    @State private var editingTeam: Team? = nil
    @State private var selectedSportFilter: String = "all"
    @State private var showPermissionAlert = false

    @EnvironmentObject var roleManager: RoleManager

    private var filteredTeams: [Team] {
        if selectedSportFilter == "all" { return teamStore.teams }
        return teamStore.teams.filter { $0.sportID == selectedSportFilter }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Sport Filter", selection: $selectedSportFilter) {
                        Text("All Sports").tag("all")
                        ForEach(SportCatalog.all, id: \.id) { sport in
                            Text(sport.displayName).tag(sport.id)
                        }
                    }
                }
                if teamStore.teams.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Teams Yet")
                            .font(.headline)
                        Text("Tap + to create your first team.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if filteredTeams.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Teams Found")
                            .font(.headline)
                        Text("Try a different sport filter.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(filteredTeams) { team in
                        Button {
                            guard roleManager.canEditRoster() else {
                                showPermissionAlert = true
                                return
                            }
                            editingTeam = team
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team.name)
                                        .font(.headline)
                                    Text(SportCatalog.sport(for: team.sportID).displayName)
                                        .font(.caption)
                                        .foregroundStyle(GoStatsTheme.text2)
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
                        guard roleManager.canEditRoster() else {
                            showPermissionAlert = true
                            return
                        }
                        for idx in indexSet {
                            let team = filteredTeams[idx]
                            teamStore.deleteTeam(team)
                        }
                    }
                }
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard roleManager.canEditRoster() else {
                            showPermissionAlert = true
                            return
                        }
                        showingCreateTeam = true
                    } label: {
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
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Coach access is required to manage teams.")
            }
        }
    }
}
