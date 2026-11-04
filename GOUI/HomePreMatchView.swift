import SwiftUI

struct HomePreMatchView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?
    var onStartMatch: (UUID) -> Void

    var body: some View {
        HomeView(
            store: store,
            teamStore: teamStore,
            selectedTeamID: $selectedTeamID,
            onStartMatch: onStartMatch
        )
    }
}
