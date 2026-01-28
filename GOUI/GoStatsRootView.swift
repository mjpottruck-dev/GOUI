import SwiftUI

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()

    // TeamStore is @Observable (Observation), so keep it as plain @State
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

