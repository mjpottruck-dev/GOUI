import SwiftUI
import UniformTypeIdentifiers

struct GoStatsRootView: View {

    @StateObject private var store = MatchStore()

    @State private var teamStore = TeamStore()

    @State private var selectedTeamID: UUID? = nil
    @State private var goToTabs = false
    @State private var showSplash = true
    @State private var incomingRosterURL: URL? = nil

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            NavigationStack {
                HomePreMatchView(
                    store: store,
                    teamStore: teamStore,
                    selectedTeamID: $selectedTeamID,
                    onStartMatch: { teamID in
                        selectedTeamID = teamID
                        if let team = teamStore.teams.first(where: { $0.id == teamID }),
                           store.currentTeamID != teamID || store.events.isEmpty {
                            store.resetForNewMatch(
                                team: team,
                                formation: team.primaryFormation,
                                seasonID: teamStore.activeSeasonID
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
