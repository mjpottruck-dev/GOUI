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
                if roleManager.role == .recruiter {
                    RecruiterSearchView()
                        .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    RecruiterSavedPlayersView()
                        .tabItem { Label("Players", systemImage: "person.text.rectangle") }
                    RecruiterSavedTeamsView()
                        .tabItem { Label("Teams", systemImage: "person.3") }
                    MoreView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                        .tabItem { Label("More", systemImage: "gearshape") }
                } else {
                    TeamHomeView(store: store, teamStore: teamStore, selectedTeamID: $appState.currentTeamID)
                        .tabItem { Label("Home", systemImage: "house") }

                    if roleManager.role == .coach {
                        if let activeTeamID {
                            TeamHubView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                                .tabItem { Label("Team", systemImage: "person.3") }
                        } else {
                            NoTeamView()
                                .tabItem { Label("Team", systemImage: "person.3") }
                        }

                        if let activeTeamID {
                            Group {
                                switch sport.scoringMode {
                                case .teamVsTeam:
                                    MatchView(store: store, clipStore: clipStore, teamStore: teamStore, teamID: activeTeamID)
                                case .individual:
                                    MeetEntryView(store: store, teamStore: teamStore, teamID: activeTeamID)
                                case .dualIndividual:
                                    DualMatchEntryView(store: store, teamStore: teamStore, teamID: activeTeamID)
                                }
                            }
                            .tabItem { Label("Game", systemImage: "sportscourt") }
                        } else {
                            NoTeamView()
                                .tabItem { Label("Game", systemImage: "sportscourt") }
                        }
                    } else {
                        if let activeTeamID {
                            ScheduleView(teamStore: teamStore, teamID: activeTeamID)
                                .tabItem { Label("Schedule", systemImage: "calendar") }
                        } else {
                            NoTeamView()
                                .tabItem { Label("Schedule", systemImage: "calendar") }
                        }
                    }

                    if let activeTeamID {
                        if roleManager.role != .coach {
                            StatsView(teamStore: teamStore, teamID: activeTeamID, sport: sport)
                                .tabItem { Label("Stats", systemImage: "chart.bar") }
                        }
                        TeamChatView(teamStore: teamStore, teamID: activeTeamID)
                            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                        MoreView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                            .tabItem { Label("More", systemImage: "ellipsis") }
                    } else {
                        NoTeamView()
                            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                    }
                }
            }
        }
    }

    private var activeTeamID: UUID? {
        let current = appState.currentTeamID
        if current != nil { return current }
        return membershipStore.activeTeamIDs(for: roleManager.userID).first ?? teamStore.teams.first?.id
    }
}
