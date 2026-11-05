import SwiftUI

struct HomeView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?
    var onStartMatch: (UUID) -> Void

    @State private var opponentName = ""
    @State private var opponentVenue = ""

    @StateObject private var sharingService = RosterSharingService()
    @State private var rippleActive = false
    @State private var showCreateTeam = false
    @State private var seasonInsight: String? = nil
    @State private var showSeasonInsightBanner = false
    @State private var showSeasonReport = false
    @State private var showSettings = false
    @State private var showTour = false
    @AppStorage(TourFlags.homeDoneKey) private var homeTourDone = false
    @AppStorage(OnboardingView.completedKey) private var onboardingDone = false

    // MARK: - Resolved helpers

    private var resolvedTeamID: UUID? {
        selectedTeamID ?? teamStore.teams.first?.id
    }

    private var resolvedTeam: Team? {
        guard let tid = resolvedTeamID else { return nil }
        return teamStore.teams.first(where: { $0.id == tid })
    }

    private var teamInitials: String {
        guard let name = resolvedTeam?.name, !name.isEmpty else { return "--" }
        return String(name.prefix(2)).uppercased()
    }

    private var startButtonTitle: String {
        if store.isActive {
            return store.isRunning ? "Game In Progress" : "Resume Game"
        }
        return "Start Match"
    }

    /// Whether the share overlay should be visible
    private var showOverlay: Bool {
        switch sharingService.state {
        case .idle, .cancelled:
            return false
        case .searching, .peerFound, .sending, .sent, .failed,
             .receivingInvite, .connecting, .received:
            return true
        }
    }

    // MARK: - W-D-L computed

    private var wins: Int {
        resolvedTeam?.matches.filter { $0.goalsFor > $0.goalsAgainst }.count ?? 0
    }
    private var draws: Int {
        resolvedTeam?.matches.filter { $0.goalsFor == $0.goalsAgainst }.count ?? 0
    }
    private var losses: Int {
        resolvedTeam?.matches.filter { $0.goalsFor < $0.goalsAgainst }.count ?? 0
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GoStatsTheme.cardGap) {

                    // -- 1. App logo icon (long-press to create team) + Settings --
                    HStack {
                        Image(systemName: "soccerball")
                            .font(.system(size: 28, weight: .regular))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                            .onLongPressGesture {
                                showCreateTeam = true
                            }
                        Spacer()
                        Button {
                            Haptics.light()
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(GoStatsTheme.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.white))
                        }
                        .accessibilityLabel("Settings")
                    }
                    .padding(.top, 14)

                    // -- 2. Team pill selector --
                    TeamPillSelector(
                        teams: teamStore.teams,
                        selectedTeamID: $selectedTeamID,
                        onCreateTeam: { showCreateTeam = true }
                    )
                    .padding(.horizontal, -GoStatsTheme.cardMargin)
                    .tourAnchor(.teamPills)

                    // -- 3. Hero card: Season Record --
                    VStack(spacing: 16) {
                        HStack {
                            sectionLabel("SEASON RECORD")
                            Spacer()

                            // Share roster button
                            Button {
                                guard let team = resolvedTeam else { return }
                                sharingService.startSharing(team: team)
                            } label: {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            }
                            .disabled(resolvedTeam == nil)
                            .tourAnchor(.shareRoster)
                        }

                        HStack(spacing: 0) {
                            // Wins
                            VStack(spacing: 4) {
                                Text("\(wins)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                Text("Wins")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(GoStatsTheme.divider)
                                .frame(width: GoStatsTheme.dividerWidth, height: 48)

                            // Draws
                            VStack(spacing: 4) {
                                Text("\(draws)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                Text("Draws")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(GoStatsTheme.divider)
                                .frame(width: GoStatsTheme.dividerWidth, height: 48)

                            // Losses
                            VStack(spacing: 4) {
                                Text("\(losses)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                Text("Losses")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .modifier(CardStyle())
                    // Anchored on a background layer, not the card itself, so it can't
                    // hide the Share button's anchor inside the card.
                    .background(Color.clear.tourAnchor(.seasonRecord))

                    // -- Season Insight Banner --
                    if showSeasonInsightBanner, let insight = seasonInsight, let team = resolvedTeam {
                        Button {
                            showSeasonReport = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundStyle(GoStatsTheme.textMuted)
                                    Text("SEASON INSIGHT")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(1)
                                        .foregroundStyle(GoStatsTheme.textMuted)
                                    Spacer()
                                    Button {
                                        withAnimation { showSeasonInsightBanner = false }
                                    } label: {
                                        Text("Dismiss")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(hex: "aaaaaa"))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(insight)
                                    .font(.system(size: 14))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(GoStatsTheme.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor,
                                            radius: GoStatsTheme.cardShadowRadius,
                                            x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }
                        .buttonStyle(.plain)
                        .navigationDestination(isPresented: $showSeasonReport) {
                            SeasonReportView(team: team, insightText: insight)
                        }
                    }

                    // -- 4. Start Match (hero button) --
                    Button {
                        guard let tid = resolvedTeamID else { return }
                        selectedTeamID = tid
                        onStartMatch(tid)
                    } label: {
                        Text(startButtonTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(GoStatsTheme.textPrimary)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(teamStore.teams.isEmpty)
                    .tourAnchor(.startMatch)

                    // -- 5. Navigation rows --
                    VStack(spacing: 10) {
                        NavigationLink {
                            if let tid = resolvedTeamID {
                                TeamRosterView(teamStore: teamStore, teamID: tid, incomingRosterURL: .constant(nil))
                            } else {
                                Text("Select a team first").foregroundStyle(.secondary)
                            }
                        } label: {
                            navRow(title: "View Roster", icon: "person.3")
                        }
                        .buttonStyle(.plain)
                        .tourAnchor(.roster)

                        NavigationLink {
                            if let tid = resolvedTeamID {
                                StatsView(teamStore: teamStore, teamID: tid)
                            } else {
                                Text("Select a team first").foregroundStyle(.secondary)
                            }
                        } label: {
                            navRow(title: "Season Stats", icon: "chart.bar")
                        }
                        .buttonStyle(.plain)
                        .tourAnchor(.seasonStats)

                        NavigationLink {
                            if let team = resolvedTeam {
                                TeamStatsView(team: team)
                            } else {
                                Text("Select a team first").foregroundStyle(.secondary)
                            }
                        } label: {
                            navRow(title: "Player Stats", icon: "person.text.rectangle")
                        }
                        .buttonStyle(.plain)
                        .tourAnchor(.playerStats)

                        NavigationLink {
                            if let tid = resolvedTeamID {
                                TeamArchiveView(teamStore: teamStore, teamID: tid)
                            } else {
                                Text("Select a team first").foregroundStyle(.secondary)
                            }
                        } label: {
                            navRow(title: "Match Archive", icon: "clock.arrow.circlepath")
                        }
                        .buttonStyle(.plain)
                        .tourAnchor(.archive)

                    }

                    // -- 6. Last match, top scorers, playing time --
                    if let team = resolvedTeam {
                        HomeInsightCards(team: team, teamStore: teamStore)
                    }
                }
                .padding(.horizontal, GoStatsTheme.cardMargin)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GoStatsTheme.bg)

            // -- Share Overlay --
            if showOverlay {
                shareOverlay
                    .transition(.opacity)
            }
        }
        .appTour(steps: AppTours.home, isActive: $showTour) {
            homeTourDone = true
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView(teamStore: teamStore)
        }
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamView(teamStore: teamStore) { newTeamID in
                selectedTeamID = newTeamID
            }
        }
        .onAppear {
            if selectedTeamID == nil {
                selectedTeamID = teamStore.teams.first?.id
            }
            sharingService.startListening()
            loadSeasonInsight()
            startTourIfNeeded()
        }
        .onChange(of: onboardingDone) { _, _ in startTourIfNeeded() }
        .onChange(of: showSettings) { _, open in
            // "Replay App Tour" in Settings takes effect when Settings closes.
            if !open { startTourIfNeeded() }
        }
        .onDisappear {
            sharingService.stopListening()
        }
        .onChange(of: selectedTeamID) { _, _ in
            showSeasonInsightBanner = false
            seasonInsight = nil
            loadSeasonInsight()
        }
        // When a roster is received, create a new team with the full roster
        .onChange(of: sharingService.receivedRoster?.teamName) { _, newName in
            print("[RosterShare-UI] onChange(receivedRoster?.teamName) fired! newName=\(newName ?? "nil")")
            guard let roster = sharingService.receivedRoster else {
                print("[RosterShare-UI]   receivedRoster is nil -- skipping")
                return
            }
            print("[RosterShare-UI]   Creating team from roster: \(roster.teamName) with \(roster.players.count) players")
            let players = roster.players.map { shared in
                Player(
                    name: shared.name,
                    number: shared.number,
                    position: Position(rawValue: shared.position) ?? .cm
                )
            }
            let goalkeeperDepth = Team.goalkeeperDepthIDs(from: players)
            let newTeam = Team(
                name: roster.teamName,
                players: players,
                startingOnFieldIDs: [],
                primaryGoalkeeperID: goalkeeperDepth.primary,
                secondaryGoalkeeperID: goalkeeperDepth.secondary,
                thirdGoalkeeperID: goalkeeperDepth.third
            )
            teamStore.addTeam(newTeam)
            selectedTeamID = newTeam.id
            print("[RosterShare-UI]   Team '\(newTeam.name)' added! ID=\(newTeam.id)")
            // Send ACK to sender AFTER team is saved
            sharingService.sendAck()
            sharingService.receivedRoster = nil
        }
        // Drive ripple on/off based on real state
        .onChange(of: sharingService.state) { _, newState in
            print("[RosterShare-UI] onChange(state) fired! newState=\(newState)")
            switch newState {
            case .searching, .connecting:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    rippleActive = true
                }
            case .peerFound, .sending, .sent, .failed, .cancelled, .idle,
                 .receivingInvite, .received:
                rippleActive = false
            }
        }
    }

    // MARK: - Guided tour

    private func startTourIfNeeded() {
        guard onboardingDone, !homeTourDone, !showTour, !teamStore.teams.isEmpty else { return }
        // Let the screen settle (and any sheet finish closing) before spotlighting.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if !homeTourDone && !showSettings {
                withAnimation { showTour = true }
            }
        }
    }

    // MARK: - Share Overlay

    private var shareOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                switch sharingService.state {

                // -- Sent Success (sender) --
                case .sent:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))

                    Text("Roster Shared Successfully!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .transition(.opacity)

                // -- Received Success (receiver) --
                case .received:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))

                    Text("Roster Received!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .transition(.opacity)

                // -- Incoming Invite (receiver) --
                case .receivingInvite(let peerName):
                    incomingInviteCard(peerName: peerName)
                        .transition(.scale.combined(with: .opacity))

                // -- Failed --
                case .failed(let message):
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.red)
                        .transition(.scale.combined(with: .opacity))

                    Text(message)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .transition(.opacity)

                // -- Searching / PeerFound / Sending --
                default:
                    ZStack {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(GoStatsTheme.teal.opacity(0.6), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(rippleActive ? 2.5 : 0.8)
                                .opacity(rippleActive ? 0 : 0.7)
                                .animation(
                                    .easeOut(duration: 2.0)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.6),
                                    value: rippleActive
                                )
                        }

                        Circle()
                            .fill(GoStatsTheme.teal)
                            .frame(width: 60, height: 60)

                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text(overlayStatusText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .animation(.easeInOut(duration: 0.2), value: overlayStatusText)
                }

                Spacer()

                // Cancel button (hidden on terminal states)
                if case .searching = sharingService.state {
                    cancelButton
                } else if case .peerFound = sharingService.state {
                    cancelButton
                } else if case .sending = sharingService.state {
                    cancelButton
                } else if case .connecting = sharingService.state {
                    cancelButton
                }

                Spacer().frame(height: 30)
            }
        }
    }

    private var overlayStatusText: String {
        switch sharingService.state {
        case .searching:
            return "Searching for nearby devices..."
        case .peerFound(let name):
            return "Found \(name)... sending"
        case .sending:
            return "Sending roster..."
        case .connecting:
            return "Receiving roster..."
        default:
            return ""
        }
    }

    private var cancelButton: some View {
        Button {
            sharingService.cancelSharing()
        } label: {
            Text("Cancel")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
        }
    }

    // MARK: - Incoming Invite Card

    private func incomingInviteCard(peerName: String) -> some View {
        GlassCard(level: .focus) {
            VStack(spacing: 16) {
                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.teal)

                Text("\(peerName) wants to share a roster")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GoStatsTheme.text)
                    .multilineTextAlignment(.center)

                Text("Their full team roster will be saved as a new team on your device.")
                    .font(.system(size: 14))
                    .foregroundStyle(GoStatsTheme.text2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        print("[RosterShare-UI] Decline button tapped")
                        sharingService.declineInvitation()
                    } label: {
                        Text("Decline")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: Color(.systemGray3)))

                    Button {
                        print("[RosterShare-UI] Accept button tapped")
                        print("[RosterShare-UI]   sharingService.receivedRoster is \(sharingService.receivedRoster == nil ? "nil" : "set")")
                        print("[RosterShare-UI]   sharingService.state = \(sharingService.state)")
                        sharingService.acceptInvitation()
                    } label: {
                        Text("Accept")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.teal))
                }
            }
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Share Roster PDF

    private func shareRosterPDF() {
        guard let team = resolvedTeam else { return }
        let starterIDs = Set(team.startingOnFieldIDs)
        let url = RosterPDFGenerator.generatePDF(team: team, starterIDs: starterIDs)
        // Present via share sheet using a temporary UIActivityViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            root.present(vc, animated: true)
        }
    }

    // MARK: - Section Label

    // MARK: - Season Insight

    private func loadSeasonInsight() {
        guard let team = resolvedTeam else { return }
        let cacheKey = "season_insight_\(team.id.uuidString)"
        let countKey = "season_insight_match_count_\(team.id.uuidString)"

        let cachedCount = UserDefaults.standard.integer(forKey: countKey)
        let currentCount = team.matches.count

        // Check if cached insight exists and is still valid
        if let cached = MatchAIService.cachedText(forKey: cacheKey), cachedCount == currentCount {
            seasonInsight = cached
            showSeasonInsightBanner = true
            return
        }

        // Check if we crossed a 3-match boundary
        guard currentCount >= 3, currentCount % 3 == 0, currentCount != cachedCount else {
            return
        }

        // Generate new insight
        let context = MatchAIService.buildSeasonContext(team: team, lastNMatches: 3)
        let systemPrompt = "You are a youth soccer season analyst. Given the last 3 matches of data for this team, provide a brief season update highlighting: overall form, top performers, and one area to focus on. Keep it encouraging and specific. 2-3 sentences. Return only the text."

        Task {
            do {
                let text = try await MatchAIService.generate(systemPrompt: systemPrompt, userMessage: context)
                await MainActor.run {
                    seasonInsight = text
                    showSeasonInsightBanner = true
                    MatchAIService.cacheText(text, forKey: cacheKey)
                    UserDefaults.standard.set(currentCount, forKey: countKey)
                }
            } catch {
                // Silently fail — don't show banner
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(GoStatsTheme.sectionHeaderColor)
    }

    // MARK: - Navigation Row

    private func navRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GoStatsTheme.textPrimary)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GoStatsTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.textMuted)
        }
        .modifier(CardStyle())
    }
}

// MARK: - Shared card modifier

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(GoStatsTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
    }
}
