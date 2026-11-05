import SwiftUI
import UniformTypeIdentifiers

struct GoStatsRootView: View {

    @StateObject private var sessionStore = MatchSessionStore()

    @State private var teamStore = TeamStore()

    @State private var selectedTeamID: UUID? = nil
    @State private var goToTabs = false
    @State private var showSplash = true
    @State private var incomingRosterURL: URL? = nil
    @StateObject private var voiceService = VoiceEventService()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(OnboardingView.completedKey) private var onboardingCompleted = false
    @State private var showOnboarding = false

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
                            // Set team name for Live Activity
                            sessionStore.liveActivityTeamName = team.name
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
                            incomingRosterURL: $incomingRosterURL,
                            onMatchSaved: { goToTabs = false }
                        )
                    } else {
                        Text("No team selected")
                    }
                }
            }
            .background(GoStatsTheme.bg)
        }
        .tint(GoStatsTheme.textPrimary)
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
            restoreInProgressMatchIfNeeded()
            decideOnboarding()
            await runSplashSequenceIfNeeded()
        }
        .fullScreenCover(isPresented: Binding(
            get: { showOnboarding && !showSplash },
            set: { showOnboarding = $0 }
        )) {
            OnboardingView(teamStore: teamStore) { newTeamID in
                if let newTeamID { selectedTeamID = newTeamID }
                onboardingCompleted = true
                showOnboarding = false
            }
        }
        .onChange(of: onboardingCompleted) { _, done in
            // Debug "Show onboarding again" flips this back to false.
            if !done { showOnboarding = true }
        }
        .onOpenURL { url in
            // A cold launch from the Live Activity mic link can arrive before .task runs.
            restoreInProgressMatchIfNeeded()
            // Handle goalstats://voice deep link from Live Activity mic button
            if url.scheme == "goalstats" && url.host == "voice" {
                handleVoiceDeepLink()
                return
            }

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
            } else if newValue == .background {
                // Last chance to save before iOS may kill the app.
                sessionStore.refreshElapsedFromClock()
                sessionStore.persist()
            }
        }
    }

    /// New coaches (only the untouched sample team) get the welcome flow. Anyone who
    /// already has a real team or saved matches skips it.
    @MainActor
    private func decideOnboarding() {
        guard !onboardingCompleted else { return }
        let hasRealData = teamStore.teams.contains { team in
            !team.matches.isEmpty || !(team.isDemo || team.name == "Demo Eleven")
        }
        if hasRealData || sessionStore.isActive {
            onboardingCompleted = true
        } else {
            showOnboarding = true
        }
    }

    /// If the app was killed mid-match, put the coach straight back into that match.
    @MainActor
    private func restoreInProgressMatchIfNeeded() {
        guard !sessionStore.isActive,
              let state = MatchStatePersistence.restore() else { return }
        guard state.isActive,
              let teamID = state.currentTeamID,
              teamStore.teams.contains(where: { $0.id == teamID }) else {
            MatchStatePersistence.clear()
            return
        }
        sessionStore.restoreState(state)
        selectedTeamID = teamID
        goToTabs = true
    }

    private func handleVoiceDeepLink() {
        guard sessionStore.isActive, !sessionStore.matchEnded else { return }

        voiceService.startListening(players: sessionStore.players) { [self] command in
            switch command {
            case .goal(let scorer, let assist):
                sessionStore.recordGoal(scorer: scorer, assist: assist)
                let name = sessionStore.displayName(for: scorer)
                sessionStore.updateLiveActivity(lastEvent: "\u{2713} Goal \u{2014} \(name)")
            case .save(let keeper):
                sessionStore.recordKeeperSave()
                let name = sessionStore.displayName(for: keeper)
                sessionStore.updateLiveActivity(lastEvent: "\u{2713} Save \u{2014} \(name)")
            case .conceded(let keeper):
                sessionStore.recordKeeperConceded()
                let name = sessionStore.displayName(for: keeper)
                sessionStore.updateLiveActivity(lastEvent: "\u{2713} Conceded \u{2014} \(name)")
            case .card(let player):
                sessionStore.recordCard(player: player, card: .yellow)
                let name = sessionStore.displayName(for: player)
                sessionStore.updateLiveActivity(lastEvent: "\u{2713} Card \u{2014} \(name)")
            case .substitution(let playerOn, let playerOff):
                // Perform sub (credit time up to now and allow undo, like a manual sub)
                sessionStore.refreshElapsedFromClock()
                sessionStore.pushUndo()
                if let index = sessionStore.onFieldLineupIDs.firstIndex(of: playerOff.id) {
                    sessionStore.onFieldLineupIDs[index] = playerOn.id
                }
                sessionStore.onFieldIDs.remove(playerOff.id)
                sessionStore.onFieldIDs.insert(playerOn.id)
                sessionStore.markPlayerSecondsBaseline()
                let onName = sessionStore.displayName(for: playerOn)
                let offName = sessionStore.displayName(for: playerOff)
                sessionStore.updateLiveActivity(lastEvent: "\u{2713} Sub \u{2014} \(onName) for \(offName)")
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

        try? await Task.sleep(nanoseconds: 800_000_000)
        withAnimation(.easeOut(duration: 0.25)) {
            showSplash = false
        }
    }
}
