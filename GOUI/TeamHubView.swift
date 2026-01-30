import SwiftUI

struct TeamHubView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore
    let teamID: UUID

    @EnvironmentObject var permissionService: PermissionService

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Team") {
                    NavigationLink("Roster") {
                        TeamRosterView(teamStore: teamStore, clipStore: clipStore, teamID: teamID)
                    }
                    NavigationLink("Stats") {
                        StatsView(teamStore: teamStore, teamID: teamID, sport: SportCatalog.sport(for: team?.sportID))
                    }
                    NavigationLink("Requests") {
                        TeamRequestsView(teamStore: teamStore, teamID: teamID)
                    }
                    NavigationLink("Settings") {
                        TeamSettingsView(teamStore: teamStore, teamID: teamID)
                    }
                }
            }
            .navigationTitle(team?.name ?? "Team")
        }
    }
}
