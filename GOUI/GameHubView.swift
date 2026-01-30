import SwiftUI

struct GameHubView: View {
    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            HomePreMatchView(
                store: store,
                teamStore: teamStore,
                selectedTeamID: $selectedTeamID
            ) { teamID, template in
                selectedTeamID = teamID
            }
        }
    }
}
