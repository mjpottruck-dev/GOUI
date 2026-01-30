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

            TabView(selection: $appState.selectedTab) {
                if roleManager.role == .recruiter {
                    RecruiterSearchView()
                        .tabItem { Label("Search", systemImage: "magnifyingglass") }
                        .tag(AppTab.search)
                    RecruiterSavedPlayersView()
                        .tabItem { Label("Players", systemImage: "person.text.rectangle") }
                        .tag(AppTab.players)
                    RecruiterSavedTeamsView()
                        .tabItem { Label("Teams", systemImage: "person.3") }
                        .tag(AppTab.teams)
                    MoreView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                        .tabItem { Label("More", systemImage: "gearshape") }
                        .tag(AppTab.more)
                } else {
                    TeamHomeView(store: store, teamStore: teamStore, selectedTeamID: $appState.currentTeamID)
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(AppTab.home)

                    if roleManager.role == .coach {
                        if let activeTeamID {
                            TeamHubView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                                .tabItem { Label("Team", systemImage: "person.3") }
                                .tag(AppTab.team)
                        } else {
                            NoTeamView()
                                .tabItem { Label("Team", systemImage: "person.3") }
                                .tag(AppTab.team)
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
                            .tag(AppTab.game)
                        } else {
                            NoTeamView()
                                .tabItem { Label("Game", systemImage: "sportscourt") }
                                .tag(AppTab.game)
                        }
                    } else {
                        if let activeTeamID {
                            ScheduleView(teamStore: teamStore, teamID: activeTeamID)
                                .tabItem { Label("Schedule", systemImage: "calendar") }
                                .tag(AppTab.schedule)
                        } else {
                            NoTeamView()
                                .tabItem { Label("Schedule", systemImage: "calendar") }
                                .tag(AppTab.schedule)
                        }
                    }

                    if let activeTeamID {
                        if roleManager.role != .coach {
                            StatsView(teamStore: teamStore, teamID: activeTeamID, sport: sport)
                                .tabItem { Label("Stats", systemImage: "chart.bar") }
                                .tag(AppTab.stats)
                        }
                        TeamChatView(teamStore: teamStore, teamID: activeTeamID)
                            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                            .tag(AppTab.chat)
                        MoreView(teamStore: teamStore, clipStore: clipStore, teamID: activeTeamID)
                            .tabItem { Label("More", systemImage: "ellipsis") }
                            .tag(AppTab.more)
                    } else {
                        NoTeamView()
                            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                            .tag(AppTab.chat)
                    }
                }
            }
        }
        .onAppear {
            ensureTabSelection()
        }
        .onChange(of: roleManager.role) { _, _ in
            ensureTabSelection()
        }
    }

    private var activeTeamID: UUID? {
        let current = appState.currentTeamID
        if current != nil { return current }
        return membershipStore.activeTeamIDs(for: roleManager.userID).first ?? teamStore.teams.first?.id
    }

    private func ensureTabSelection() {
        let allowedTabs: [AppTab]
        switch roleManager.role {
        case .recruiter:
            allowedTabs = [.search, .players, .teams, .more]
        case .coach:
            allowedTabs = [.home, .team, .game, .chat, .more]
        default:
            allowedTabs = [.home, .schedule, .stats, .chat, .more]
        }

        if !allowedTabs.contains(appState.selectedTab) {
            appState.selectedTab = allowedTabs.first ?? .home
        }
    }
}
