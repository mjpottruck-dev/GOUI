// CODEX SYNC TEST
import SwiftUI

struct MainTabsView: View {

    @ObservedObject var store: MatchStore
    @ObservedObject var clipStore: ClipStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @EnvironmentObject var roleManager: RoleManager

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
                    clipStore: clipStore,
                    teamStore: teamStore,
                    teamID: teamID
                )
                .tabItem { Label("Match", systemImage: "soccerball") }

                TeamRosterView(teamStore: teamStore, teamID: teamID)
                    .tabItem { Label("Roster", systemImage: "person.3") }

                StatsView(teamStore: teamStore, teamID: teamID, sport: sport)
                    .tabItem { Label("Stats", systemImage: "chart.bar") }

                HighlightsHubView(
                    matchStore: store,
                    clipStore: clipStore,
                    teamStore: teamStore,
                    teamID: teamID
                )
                .tabItem { Label("Highlights", systemImage: "film") }

                if roleManager.role == .clubAdmin {
                    ClubDashboardView(teamStore: teamStore)
                        .tabItem { Label("Club", systemImage: "building.2") }
                }

                SettingsView(teamStore: teamStore, clipStore: clipStore)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}
