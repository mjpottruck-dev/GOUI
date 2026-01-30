import SwiftUI

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()
    @StateObject private var clipStore = ClipStore()

    @State private var teamStore = TeamStore()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var roleManager = RoleManager()
    @StateObject private var clubStore = ClubStore()
    @StateObject private var analytics = AnalyticsService.shared

    @State private var selectedTeamID: UUID? = nil
    @State private var goToTabs = false
    @State private var showSplash = true
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            NavigationStack {
                HomePreMatchView(
                    store: store,
                    teamStore: teamStore,
                    selectedTeamID: $selectedTeamID,
                    onStartMatch: { teamID, template in
                        selectedTeamID = teamID
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
                    if let tid = selectedTeamID {
                        MainTabsView(
                            store: store,
                            clipStore: clipStore,
                            teamStore: teamStore,
                            teamID: tid
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
            if !showSplash && roleManager.needsOnboarding {
                showOnboarding = true
            }
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
