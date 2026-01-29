// CODEX SYNC TEST
import SwiftUI

struct MainTabsView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            TabView {
                MatchView(
                    store: store,
                    teamStore: teamStore,
                    teamID: teamID
                )
                .tabItem { Label("Match", systemImage: "soccerball") }

                TeamRosterView(teamStore: teamStore, teamID: teamID)
                    .tabItem { Label("Roster", systemImage: "person.3") }

                StatsView(teamStore: teamStore, teamID: teamID)
                    .tabItem { Label("Stats", systemImage: "chart.bar") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}
