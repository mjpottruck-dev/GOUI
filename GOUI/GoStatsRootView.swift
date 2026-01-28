import SwiftUI

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()

    @State private var teamStore = TeamStore()

    @State private var selectedTeamID: UUID? = nil
    @State private var goToTabs = false

    var body: some View {
        NavigationStack {
            HomePreMatchView(
                store: store,
                teamStore: teamStore,
                selectedTeamID: $selectedTeamID,
                onStartMatch: { teamID in
                    selectedTeamID = teamID
                    if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                        store.resetForNewMatch(
                            team: team,
                            formation: team.primaryFormation,
                            seasonID: teamStore.activeSeasonID
                        )
                    }
                    goToTabs = true
                }
            )
            .navigationDestination(isPresented: $goToTabs) {
                if let tid = selectedTeamID {
                    MainTabsView(
                        store: store,
                        teamStore: teamStore,
                        teamID: tid
                    )
                } else {
                    Text("No team selected")
                }
            }
        }
    }
}
