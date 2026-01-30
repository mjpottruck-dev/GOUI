import SwiftUI

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()
    @StateObject private var clipStore = ClipStore()

    @State private var teamStore = TeamStore()
    @StateObject private var authManager: AuthManager
    @StateObject private var subscriptionManager: SubscriptionManager
    @StateObject private var roleManager: RoleManager
    @StateObject private var membershipStore: TeamMembershipStore
    @StateObject private var permissionService: PermissionService
    @StateObject private var clubStore = ClubStore()
    @StateObject private var analytics = AnalyticsService.shared
    @StateObject private var joinRequestStore = JoinRequestStore()
    @StateObject private var statKeeperRequestStore = StatKeeperRequestStore()
    @StateObject private var chatStore = ChatStore()
    @StateObject private var sharingService = SharingService()

    @StateObject private var appState: AppState
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var demoModeEnabled = false

    init() {
        let authManager = AuthManager()
        let roleManager = RoleManager()
        let subscriptionManager = SubscriptionManager()
        let membershipStore = TeamMembershipStore()
        _authManager = StateObject(wrappedValue: authManager)
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

            MainTabsView(
                store: store,
                clipStore: clipStore,
                teamStore: teamStore
            )
            .background(GoStatsTheme.bg)
        }
        .tint(GoStatsTheme.primary)
        .environmentObject(authManager)
        .environmentObject(subscriptionManager)
        .environmentObject(roleManager)
        .environmentObject(membershipStore)
        .environmentObject(permissionService)
        .environmentObject(appState)
        .environmentObject(clubStore)
        .environmentObject(analytics)
        .environmentObject(joinRequestStore)
        .environmentObject(statKeeperRequestStore)
        .environmentObject(chatStore)
        .environmentObject(sharingService)
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
        .overlay {
            if shouldRequireAuth {
                SignInView {
                    demoModeEnabled = true
                }
            }
        }
        .task {
            await runSplashSequenceIfNeeded()
            analytics.log(.appOpen)
            membershipStore.updateCloudSyncEnabled(teamStore.cloudSyncEnabled)
            membershipStore.bootstrapMemberships(for: teamStore, userID: roleManager.userID, defaultRole: .manager)
            teamStore.assignManagerIfNeeded(userID: roleManager.userID)
            if appState.currentTeamID == nil {
                appState.currentTeamID = membershipStore.activeTeamIDs(for: roleManager.userID).first ?? teamStore.teams.first?.id
            }
            if !showSplash && roleManager.needsOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: authManager.currentUser) { _, newUser in
            roleManager.applyAuthUser(newUser)
            if let user = newUser {
                membershipStore.bootstrapMemberships(for: teamStore, userID: user.userID, defaultRole: .manager)
                teamStore.assignManagerIfNeeded(userID: user.userID)
                if appState.currentTeamID == nil {
                    appState.currentTeamID = membershipStore.activeTeamIDs(for: user.userID).first ?? teamStore.teams.first?.id
                }
                Task {
                    await migrateLocalTeamsIfNeeded(for: user)
                }
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

    private var shouldRequireAuth: Bool {
        false
    }

    private func migrateLocalTeamsIfNeeded(for user: AuthUser) async {
        let key = "migration.completed.\(user.userID)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        for team in teamStore.teams where team.shareRecordName == nil {
            do {
                let share = try await sharingService.createShare(for: team)
                teamStore.updateShareRecordName(teamID: team.id, shareRecordName: share.recordID.recordName)
            } catch {
                print("❌ Migration share failed:", error)
            }
        }
        UserDefaults.standard.set(true, forKey: key)
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
