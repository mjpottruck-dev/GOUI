import SwiftUI

struct RootView: View {

    @State private var selectedTeamID: UUID? = nil

    // MatchStore is ObservableObject ✅
    @StateObject private var store = MatchStore()

    // TeamStore is @Observable (Observation) ✅ -> use @State (NOT StateObject)
    @State private var teamStore = TeamStore()

    var body: some View {
        MainTabsView(
            store: store,
            teamStore: teamStore,
            selectedTeamID: $selectedTeamID
        )
    }
}

