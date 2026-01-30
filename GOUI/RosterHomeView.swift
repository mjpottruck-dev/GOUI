import SwiftUI

struct RosterHomeView: View {

    @Bindable var teamStore: TeamStore

    @State private var showingCreateTeam = false
    @State private var editingTeam: Team? = nil
    @State private var selectedSportFilter: String = "all"
    @State private var showPermissionAlert = false
    @State private var showJoinTeam = false

    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService

    private var filteredTeams: [Team] {
        let availableTeams = teamStore.teams.filter { activeTeamIDs.contains($0.id) }
        if selectedSportFilter == "all" { return availableTeams }
        return availableTeams.filter { $0.sportID == selectedSportFilter }
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
                            guard permissionService.canEditRoster(teamID: team.id) else {
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
                        for idx in indexSet {
                            let team = filteredTeams[idx]
                            guard permissionService.canEditRoster(teamID: team.id) else {
                                showPermissionAlert = true
                                return
                            }
                            teamStore.deleteTeam(team)
                        }
                    }
                }
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard roleManager.role == .coach || permissionService.canEditRoster(teamID: filteredTeams.first?.id ?? UUID()) else {
                            showPermissionAlert = true
                            return
                        }
                        showingCreateTeam = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Join") {
                        showJoinTeam = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateTeam) {
                CreateTeamView(teamStore: teamStore) { _ in
                    // CreateTeamView already adds the team + dismisses.
                    showingCreateTeam = false
                }
            }
            .sheet(isPresented: $showJoinTeam) {
                JoinTeamByCodeView(teamStore: teamStore)
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

    private var activeTeamIDs: Set<UUID> {
        let activeIDs = membershipStore.activeTeamIDs(for: roleManager.userID)
        if activeIDs.isEmpty {
            return Set(teamStore.teams.map(\.id))
        }
        return Set(activeIDs)
    }
}
