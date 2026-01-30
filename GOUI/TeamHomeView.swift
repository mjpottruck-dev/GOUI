import SwiftUI

struct TeamHomeView: View {
    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?

    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var membershipStore: TeamMembershipStore

    @State private var showTeamSwitcher = false
    @State private var showCreateTeam = false
    @State private var showJoinTeam = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    teamSwitcher

                    myTeamsSection

                    HStack(spacing: 12) {
                        Button {
                            showCreateTeam = true
                        } label: {
                            Label("Create Team", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showJoinTeam = true
                        } label: {
                            Label("Join Team", systemImage: "person.crop.circle.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    NavigationLink("Go to Match Setup") {
                        HomePreMatchView(
                            store: store,
                            teamStore: teamStore,
                            selectedTeamID: $selectedTeamID
                        ) { teamID, template in
                            selectedTeamID = teamID
                            if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                                store.resetForNewMatch(
                                    team: team,
                                    formation: team.primaryFormation,
                                    seasonID: teamStore.activeSeasonID(for: teamID),
                                    template: template
                                )
                            }
                        }
                    }
                    .buttonStyle(.bordered)

                    Spacer(minLength: 16)
                }
                .padding(16)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTeamSwitcher = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showTeamSwitcher) {
                TeamSwitcherSheet(teamStore: teamStore) { picked in
                    selectedTeamID = picked
                }
            }
            .sheet(isPresented: $showCreateTeam) {
                CreateTeamView(teamStore: teamStore) { teamID in
                    selectedTeamID = teamID
                }
            }
            .sheet(isPresented: $showJoinTeam) {
                JoinTeamByCodeView(teamStore: teamStore)
            }
            .onAppear {
                if selectedTeamID == nil {
                    selectedTeamID = activeTeams.first?.id
                }
            }
        }
    }

    private var activeTeams: [Team] {
        let activeIDs = membershipStore.activeTeamIDs(for: roleManager.userID)
        let resolved = activeIDs.isEmpty ? teamStore.teams : teamStore.teams.filter { activeIDs.contains($0.id) }
        return resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var teamSwitcher: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Team")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Picker("Team", selection: Binding(
                    get: { selectedTeamID ?? activeTeams.first?.id },
                    set: { selectedTeamID = $0 }
                )) {
                    ForEach(activeTeams) { team in
                        Text(team.name).tag(Optional(team.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var myTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Teams")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.primary)

            if activeTeams.isEmpty {
                LiquidGlassContainer(cornerRadius: 22) {
                    Text("No active teams yet.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(activeTeams) { team in
                    LiquidGlassContainer(cornerRadius: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)
                                Text(SportCatalog.sport(for: team.sportID).displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                            Spacer()
                            if team.id == selectedTeamID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(GoStatsTheme.primary)
                            }
                        }
                    }
                    .onTapGesture { selectedTeamID = team.id }
                }
            }
        }
    }
}
