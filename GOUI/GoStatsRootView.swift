import SwiftUI

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()

    @State private var teamStore = TeamStore()

    @State private var selectedTeamID: UUID? = nil
    @State private var goToTabs = false
    @State private var showSplash = true

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
