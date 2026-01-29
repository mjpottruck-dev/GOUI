// CODEX SYNC TEST
import SwiftUI

struct MainTabsView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    private var sport: any SportDefinition {
        let team = teamStore.teams.first(where: { $0.id == teamID })
        return SportCatalog.sport(for: team?.sportID)
    }

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

                StatsView(teamStore: teamStore, teamID: teamID, sport: sport)
                    .tabItem { Label("Stats", systemImage: "chart.bar") }

                SettingsView(teamStore: teamStore)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}
