import SwiftUI

struct MainTabsView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    var body: some View {
        TabView {
            // ✅ MATCH TAB FIRST
            MatchView(
                store: store,
                teamStore: teamStore,
                teamID: teamID
            )
            .tabItem { Label("Match", systemImage: "soccerball") }

            // ✅ ROSTER TAB (team roster / players)
            // If you already have a better roster view for a single team, swap it here.
            TeamRosterView(teamStore: teamStore, teamID: teamID)
                .tabItem { Label("Roster", systemImage: "person.3") }

            // ✅ STATS TAB (your StatsView requires store:)
            StatsView(store: store)
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

