// CODEX SYNC TEST
import SwiftUI

struct MainTabsView: View {

    @ObservedObject var store: MatchStore
    @ObservedObject var clipStore: ClipStore
    @Bindable var teamStore: TeamStore
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService

    private var sport: any SportDefinition {
        let team = teamStore.teams.first(where: { $0.id == activeTeamID })
        return SportCatalog.sport(for: team?.sportID)
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            TabView {
                if let activeTeamID {
                    MatchView(
                        store: store,
                        clipStore: clipStore,
                        teamStore: teamStore,
                        teamID: activeTeamID
                    )
                    .tabItem { Label("Match", systemImage: "soccerball") }

                    TeamRosterView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                        .tabItem { Label("Roster", systemImage: "person.3") }

                    StatsView(teamStore: teamStore, teamID: activeTeamID, sport: sport)
                        .tabItem { Label("Stats", systemImage: "chart.bar") }

                    HighlightsHubView(
                        matchStore: store,
                        clipStore: clipStore,
                        teamStore: teamStore,
                        teamID: activeTeamID
                    )
                    .tabItem { Label("Highlights", systemImage: "film") }
                } else {
                    NoTeamView()
                        .tabItem { Label("Match", systemImage: "soccerball") }
                }

                if subscriptionManager.entitlements.clubDashboard {
                    ClubDashboardView(teamStore: teamStore)
                        .tabItem { Label("Club", systemImage: "building.2") }
                }

                if roleManager.role == .recruiter {
                    RecruiterPortalView(teamStore: teamStore, clipStore: clipStore)
                        .tabItem { Label("Recruiter", systemImage: "magnifyingglass") }
                }

                SettingsView(teamStore: teamStore, clipStore: clipStore)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
    }

    private var activeTeamID: UUID? {
        let current = appState.currentTeamID
        if current != nil { return current }
        return membershipStore.activeTeamIDs(for: roleManager.userID).first ?? teamStore.teams.first?.id
    }
}
