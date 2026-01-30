import SwiftUI

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()
    @StateObject private var clipStore = ClipStore()

    @State private var teamStore = TeamStore()
    @StateObject private var subscriptionManager: SubscriptionManager
    @StateObject private var roleManager: RoleManager
    @StateObject private var membershipStore: TeamMembershipStore
    @StateObject private var permissionService: PermissionService
    @StateObject private var clubStore = ClubStore()
    @StateObject private var analytics = AnalyticsService.shared

    @StateObject private var appState: AppState
    @State private var goToTabs = false
    @State private var showSplash = true
    @State private var showOnboarding = false

    init() {
        let roleManager = RoleManager()
        let subscriptionManager = SubscriptionManager()
        let membershipStore = TeamMembershipStore()
        _roleManager = StateObject(wrappedValue: roleManager)
        _subscriptionManager = StateObject(wrappedValue: subscriptionManager)
        _membershipStore = StateObject(wrappedValue: membershipStore)
        _permissionService = StateObject(wrappedValue: PermissionService(
            roleManager: roleManager,
            membershipStore: membershipStore,
            subscriptionManager: subscriptionManager
        ))
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            NavigationStack {
                HomePreMatchView(
                    store: store,
                    teamStore: teamStore,
                    selectedTeamID: $appState.currentTeamID,
                    onStartMatch: { teamID, template in
                        appState.currentTeamID = teamID
                        if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                            store.resetForNewMatch(
                                team: team,
                                formation: team.primaryFormation,
                                seasonID: teamStore.activeSeasonID(for: teamID),
                                template: template
                            )
                        }
                        goToTabs = true
                    }
                )
                .navigationDestination(isPresented: $goToTabs) {
                    if appState.currentTeamID != nil {
                        MainTabsView(
                            store: store,
                            clipStore: clipStore,
                            teamStore: teamStore
                        )
                    } else {
                        Text("No team selected")
                    }
                }
            }
            .background(GoStatsTheme.bg)
        }
        .tint(GoStatsTheme.primary)
        .environmentObject(subscriptionManager)
        .environmentObject(roleManager)
        .environmentObject(membershipStore)
        .environmentObject(permissionService)
        .environmentObject(appState)
        .environmentObject(clubStore)
        .environmentObject(analytics)
        .overlay {
            if showSplash {
                SplashView(onSkip: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSplash = false
                    }
                })
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(teamStore: teamStore)
                .environmentObject(roleManager)
                .environmentObject(clubStore)
                .environmentObject(subscriptionManager)
                .environmentObject(analytics)
        }
        .task {
            await runSplashSequenceIfNeeded()
            analytics.log(.appOpen)
            membershipStore.updateCloudSyncEnabled(teamStore.cloudSyncEnabled)
            membershipStore.bootstrapMemberships(for: teamStore, userID: roleManager.userID, defaultRole: .coachManager)
            if appState.currentTeamID == nil {
                appState.currentTeamID = membershipStore.activeTeamIDs(for: roleManager.userID).first ?? teamStore.teams.first?.id
            }
            if !showSplash && roleManager.needsOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: teamStore.cloudSyncEnabled) { _, newValue in
            membershipStore.updateCloudSyncEnabled(newValue)
        }
        .onChange(of: showSplash) { _, newValue in
            if !newValue, roleManager.needsOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: roleManager.needsOnboarding) { _, needs in
            if !showSplash && needs {
                showOnboarding = true
            }
        }
    }

    @MainActor
    private func runSplashSequenceIfNeeded() async {
        #if DEBUG
        if DebugSettings.skipSplashEnabled {
            showSplash = false
            return
        }
        #endif

        try? await Task.sleep(nanoseconds: 3_000_000_000)
        withAnimation(.easeOut(duration: 0.25)) {
            showSplash = false
        }
    }
}
