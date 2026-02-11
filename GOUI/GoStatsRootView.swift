import SwiftUI
import UniformTypeIdentifiers

struct GoStatsRootView: View {

    @StateObject private var sessionStore = MatchSessionStore()

    @State private var teamStore = TeamStore()

    @State private var selectedTeamID: UUID? = nil
    @State private var goToTabs = false
    @State private var showSplash = true
    @State private var incomingRosterURL: URL? = nil
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            NavigationStack {
                HomePreMatchView(
                    store: sessionStore,
                    teamStore: teamStore,
                    selectedTeamID: $selectedTeamID,
                    onStartMatch: { teamID in
                        selectedTeamID = teamID
                        if let team = teamStore.teams.first(where: { $0.id == teamID }),
                           !sessionStore.isActive || sessionStore.currentTeamID != teamID {
                            sessionStore.resetForNewMatch(
                                team: team,
                                formation: team.primaryFormation,
                                seasonID: teamStore.activeSeasonID
                            )
                        }
                        sessionStore.refreshElapsedFromClock()
                        goToTabs = true
                    }
                )
                .navigationDestination(isPresented: $goToTabs) {
                    if let tid = selectedTeamID {
                        MainTabsView(
                            store: sessionStore,
                            teamStore: teamStore,
                            teamID: tid,
                            incomingRosterURL: $incomingRosterURL
                        )
                    } else {
                        Text("No team selected")
                    }
                }
            }
            .background(GoStatsTheme.bg)
        }
        .tint(GoStatsTheme.primary)
        .environmentObject(sessionStore)
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
        .task {
            await runSplashSequenceIfNeeded()
        }
        .onOpenURL { url in
            let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
            let matchesType = (contentType?.conforms(to: .goUIRoster) == true)
                || (contentType?.conforms(to: .json) == true)
            if matchesType || url.pathExtension.lowercased() == "json" {
                incomingRosterURL = url
                if !goToTabs, let teamID = selectedTeamID ?? teamStore.teams.first?.id {
                    selectedTeamID = teamID
                    goToTabs = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                sessionStore.refreshElapsedFromClock()
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
