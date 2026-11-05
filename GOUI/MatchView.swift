import SwiftUI

struct MatchView: View {

    @EnvironmentObject private var store: MatchSessionStore
    var teamStore: TeamStore
    let teamID: UUID
    var onMatchSaved: (() -> Void)? = nil

    @Environment(\.scenePhase) private var scenePhase

    @State private var showingEndSheet = false
    @State private var showHaptics = true
    @State private var showFormationPicker = false
    @State private var showPauseOptions = false
    @State private var showResetConfirm = false

    @State private var activeQuickEvent: MatchActionKind? = nil
    @State private var showFieldOverlay = false
    @State private var pendingScorer: Player? = nil
    @State private var pendingPlayer: Player? = nil
    @State private var pendingShotIsPenalty = false
    @State private var showAssistPicker = false
    @State private var showShotDialog = false
    @State private var showCardDialog = false
    @State private var showSubSheet = false
    @State private var showLineChangeSheet = false

    @StateObject private var voiceService = VoiceEventService()
    @AppStorage("substitution_suggestions_enabled") private var subSuggestionsEnabled = true
    @State private var suggestionBanner: SubSuggestionBanner? = nil
    @State private var dismissedSuggestionPlayerIDs: Set<UUID> = []
    @State private var lastSuggestionCheckMinute: Int = -10
    @State private var showTour = false
    @State private var showFormatSheet = false
    @AppStorage(TourFlags.matchDoneKey) private var matchTourDone = false

    private var resolvedFormation: Formation {
        store.formation ?? Formation.allCases.first!
    }

    // MARK: - State Machine
    // State 1: Pre-match  (!isActive)
    // State 2: Running 1H (isActive, isRunning, !hasSplitHalf)
    // State 3: Paused 1H  (isActive, !isRunning, !hasSplitHalf, !matchEnded)
    // State 4: Halftime   (isActive, !isRunning, hasSplitHalf, elapsed==0, !matchEnded)
    // State 5: Running 2H (isActive, isRunning, hasSplitHalf)
    // State 6: Paused 2H  (isActive, !isRunning, hasSplitHalf, !matchEnded, elapsed>0 or just paused)
    // State 7: Ended      (matchEnded)

    /// In the last period (2nd half or Q4): End is available and pausing doesn't offer a break.
    private var isSecondHalf: Bool { store.isFinalPeriod }
    private var showEndMatch: Bool {
        // End Match only in states 5 and 6
        // Also shown after the match is ended, so Cancel on the End sheet (or a restore
        // after a crash) never leaves the coach with no way to save the match.
        store.isActive && (isSecondHalf || store.matchEnded)
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    scoreCard.tourAnchor(.matchClock)
                    controlRow.tourAnchor(.matchControls)
                    quickEventsTeam.tourAnchor(.teamEvents)
                    quickEventsKeeper.tourAnchor(.keeperEvents)
                    fieldCard
                    MatchTimelineView(events: store.events)
                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .overlay(fieldOverlay)
            .overlay(alignment: .bottom) {
                if let toast = voiceService.toastMessage {
                    Text(toast)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(GoStatsTheme.textPrimary)
                        )
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3), value: toast)
                }
            }
            .overlay(alignment: .bottom) {
                if let banner = suggestionBanner {
                    suggestionBannerView(banner)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .appTour(steps: AppTours.match, isActive: $showTour) {
            matchTourDone = true
        }
        .onAppear {
            // First time on the match screen: explain it (before the clock starts).
            guard !matchTourDone, !store.isRunning else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if !matchTourDone { withAnimation { showTour = true } }
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Reset") { showResetConfirm = true }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
            }
        }
        .sheet(isPresented: $showingEndSheet) {
            if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                EndMatchSheet(store: store, teamStore: teamStore, teamID: teamID, team: team, formation: resolvedFormation, onMatchSaved: onMatchSaved)
            }
        }
        .sheet(isPresented: $showFormationPicker) {
            FormationPickerSheet(fieldSize: store.fieldSize) { formation in
                store.formation = formation
            }
        }
        .confirmationDialog("Shot Result", isPresented: $showShotDialog, titleVisibility: .visible) {
            Button("On Target") { confirmShot(onTarget: true) }
            Button("Off Target") { confirmShot(onTarget: false) }
            Button("Cancel", role: .cancel) { pendingPlayer = nil; pendingShotIsPenalty = false; activeQuickEvent = nil }
        }
        .confirmationDialog("Card", isPresented: $showCardDialog, titleVisibility: .visible) {
            Button(CardType.yellow.rawValue) { confirmCard(type: .yellow) }
            Button(CardType.red.rawValue) { confirmCard(type: .red) }
            Button("Cancel", role: .cancel) { pendingPlayer = nil; activeQuickEvent = nil }
        }
        .sheet(isPresented: $showSubSheet) {
            SubstitutionSheet(store: store, onSwap: attemptSwap)
        }
        .sheet(isPresented: $showLineChangeSheet) {
            LineChangeSheet(store: store)
        }
        // Pause before the final period: just pause, or end the half / quarter
        .confirmationDialog("Clock Paused", isPresented: $showPauseOptions, titleVisibility: .visible) {
            Button("Pause") {
                // Stay paused, label unchanged
            }
            Button(store.periodCount == 4 ? "End \(store.periodName)" : "Halftime") {
                store.endPeriod()
            }
            Button("Cancel", role: .cancel) {
                store.startGame() // resume on cancel
            }
        } message: {
            Text(store.periodCount == 4
                 ? "Choose Pause to hold the clock, or End \(store.periodName) to start the next quarter when you resume."
                 : "Choose Pause to hold the clock, or Halftime to start the 2nd half when you resume.")
        }
        .sheet(isPresented: $showFormatSheet) {
            MatchFormatSheet(store: store, teamStore: teamStore, teamID: teamID)
        }
        .overlay(alignment: .top) {
            if store.periodTimeUp && store.isRunning && !store.matchEnded {
                periodTimeUpBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: store.periodTimeUp)
        .confirmationDialog("Reset current match?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset Match", role: .destructive) {
                if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                    store.resetForNewMatch(team: team, formation: resolvedFormation, seasonID: teamStore.activeSeasonID)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears timer, score, events, and live player stats.")
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active { store.refreshElapsedFromClock() }
        }
        .onChange(of: store.elapsedSeconds) { _, newSeconds in
            let currentMinute = newSeconds / 60
            // Check every 5 minutes of match time
            if subSuggestionsEnabled,
               store.isRunning,
               currentMinute >= lastSuggestionCheckMinute + 5 {
                lastSuggestionCheckMinute = currentMinute
                checkForSubSuggestions(minute: currentMinute)
            }
        }
    }

    // MARK: - Score Card (burnt orange #E8621A, white text, no black)

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if !store.matchEnded {
                    Button(action: handleStartPause) {
                        Text(primaryControlTitle)
                            .font(.custom("DM Sans", size: 14).weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.rButton, style: .continuous)
                                    .fill(Color.white)
                            )
                            .foregroundStyle(GoStatsTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if store.isActive && !store.matchEnded {
                    Button {
                        if voiceService.isListening {
                            voiceService.stopListening()
                        } else {
                            voiceService.startListening(players: store.players) { command in
                                handleVoiceCommand(command)
                            }
                        }
                    } label: {
                        Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.scoreText)
                            .opacity(voiceService.isListening ? 1.0 : 0.6)
                            .scaleEffect(voiceService.isListening ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: voiceService.isListening)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }

                if !store.isActive {
                    // Before kickoff: tap to choose halves/quarters and length.
                    Button {
                        Haptics.light()
                        showFormatSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(store.formatDescription.uppercased())
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .font(.custom("DM Sans", size: 10).weight(.semibold)).tracking(1)
                        .foregroundStyle(GoStatsTheme.scoreText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Match format, \(store.formatDescription). Change")
                } else {
                    Text(store.periodLabel)
                        .font(.custom("DM Sans", size: 10).weight(.medium)).tracking(1)
                        .foregroundStyle(GoStatsTheme.scoreMuted)
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.timeString)
                        .font(.custom("DM Mono", size: 26))
                        .foregroundStyle(GoStatsTheme.scoreText)
                    Text(timeCaption)
                        .font(.custom("DM Sans", size: 10).weight(.medium)).tracking(1)
                        .foregroundStyle(timeCaptionIsOver ? GoStatsTheme.accent : GoStatsTheme.scoreMuted)
                        .monospacedDigit()
                }
                Spacer()
                Text("\(store.goalsFor) - \(store.goalsAgainst)")
                    .font(.custom("DM Mono", size: 40))
                    .foregroundStyle(GoStatsTheme.scoreText)
            }
        }
        .padding(GoStatsTheme.s16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(GoStatsTheme.scoreBg)
        )
    }

    // MARK: - Controls (all buttons same height on one line)

    private var controlRow: some View {
        HStack(spacing: 8) {
            controlButton(icon: "arrow.uturn.backward", label: "Undo") {
                if store.canUndo { haptic(.medium); store.undoLast() }
                else { Haptics.undoEmpty() }
            }
            .disabled(!store.canUndo)
            .opacity(store.canUndo ? 1 : 0.4)

            controlButton(icon: "arrow.triangle.2.circlepath", label: "Sub") {
                haptic(.light); showSubSheet = true
            }

            controlButton(icon: "rectangle.2.swap", label: nil) {
                haptic(.light); showLineChangeSheet = true
            }

            if showEndMatch {
                Button {
                    haptic(.light)
                    store.endMatchFreeze()
                    showingEndSheet = true
                } label: {
                    Text("End")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 36)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rButton, style: .continuous)
                                .fill(GoStatsTheme.textPrimary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func controlButton(icon: String, label: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                if let label {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(GoStatsTheme.textPrimary)
            .frame(height: 36)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.rButton, style: .continuous)
                    .stroke(GoStatsTheme.controlGray, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Events

    private var quickEventsTeam: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader("QUICK EVENTS - TEAM")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    eventButton("Goal",       tint: .goal)    { startQuickEvent(.goal) }
                    eventButton("Shot",       tint: .white)   { startQuickEvent(.shot) }
                    eventButton("Own Goal",   tint: .white)   { startQuickEvent(.ownGoal) }
                    eventButton("PK Attempt", tint: .white)   { startQuickEvent(.pkAttempt) }
                    eventButton("Card",       tint: .white)   { startQuickEvent(.card) }
                    eventButton("PK Made",    tint: .white)   { startQuickEvent(.pkMade) }
                }
            }
        }
    }

    private var quickEventsKeeper: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                GoStatsTheme.sectionHeader("QUICK EVENTS - KEEPER")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    eventButton("Save",        tint: .greenTint) { store.recordKeeperSave() }
                    eventButton("Conceded",    tint: .redTint)   { store.recordKeeperConceded() }
                    eventButton("PK Saved",    tint: .greenTint) { store.recordKeeperPKSaved() }
                    eventButton("PK Conceded", tint: .redTint)   { store.recordKeeperConceded(isPenalty: true) }
                }
            }
        }
    }

    private enum EventTint { case goal, white, greenTint, redTint }

    private func eventButton(_ title: String, tint: EventTint, action: @escaping () -> Void) -> some View {
        Button { haptic(.light); action() } label: {
            Text(title)
                .font(.custom("DM Sans", size: 16).weight(.medium))
                .foregroundStyle(tint == .goal ? .white : GoStatsTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                        .fill(eventFill(tint))
                        .shadow(color: GoStatsTheme.cardShadowColor,
                                radius: GoStatsTheme.cardShadowRadius,
                                x: 0, y: GoStatsTheme.cardShadowY)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                        .stroke(tint == .goal ? Color.clear : GoStatsTheme.cardBorder,
                                lineWidth: GoStatsTheme.cardBorderWidth)
                )
        }
        .buttonStyle(.plain)
    }

    private func eventFill(_ tint: EventTint) -> Color {
        switch tint {
        case .goal:      return GoStatsTheme.positive
        case .white:     return Color.white
        case .greenTint: return GoStatsTheme.greenTint
        case .redTint:   return GoStatsTheme.redTint
        }
    }

    private var fieldCard: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    GoStatsTheme.sectionHeader("FIELD")
                    Spacer()
                    Button(resolvedFormation.rawValue) { showFormationPicker = true }
                        .font(.custom("DM Sans", size: 10).weight(.medium)).tracking(1)
                        .foregroundStyle(GoStatsTheme.textMuted)
                }
                FieldView1443(store: store)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var fieldOverlay: some View {
        Group {
            if showFieldOverlay, let currentQuickEvent = activeQuickEvent {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 16) {
                        LiquidGlassContainer(cornerRadius: GoStatsTheme.rCard) {
                            VStack(alignment: .leading, spacing: 6) {
                                GoStatsTheme.sectionHeader("SELECT PLAYER")
                                Text("Tap a player on the field.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                        }
                        .padding(.horizontal, 16)

                        FieldView1443(store: store, onSelectPlayer: { player in
                            handleFieldSelection(player, for: currentQuickEvent)
                        })
                        .padding(.horizontal, 16)

                        Button {
                            showFieldOverlay = false; activeQuickEvent = nil
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .frame(maxWidth: 180)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .stroke(GoStatsTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 24)
                }
            }
            if showAssistPicker, let scorer = pendingScorer {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 16) {
                        LiquidGlassContainer(cornerRadius: GoStatsTheme.rCard) {
                            VStack(alignment: .leading, spacing: 6) {
                                GoStatsTheme.sectionHeader("SELECT ASSIST")
                                Text("Tap a player on the field.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                        }
                        .padding(.horizontal, 16)

                        FieldView1443(store: store, onSelectPlayer: { player in
                            store.recordGoal(scorer: scorer, assist: player)
                            pendingScorer = nil; showAssistPicker = false
                        })
                        .padding(.horizontal, 16)

                        Button {
                            store.recordGoal(scorer: scorer, assist: nil)
                            pendingScorer = nil; showAssistPicker = false
                        } label: {
                            Text("No Assist").frame(maxWidth: 180)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .stroke(GoStatsTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Quick Event Flow

    private func startQuickEvent(_ kind: MatchActionKind) {
        activeQuickEvent = kind; showFieldOverlay = true
    }

    private func handleFieldSelection(_ player: Player, for kind: MatchActionKind) {
        showFieldOverlay = false
        switch kind {
        case .goal:      pendingScorer = player; showAssistPicker = true
        case .shot:      pendingPlayer = player; pendingShotIsPenalty = false; showShotDialog = true
        case .pkAttempt: pendingPlayer = player; pendingShotIsPenalty = true; showShotDialog = true
        case .card:      pendingPlayer = player; showCardDialog = true
        case .pkMade:    store.recordPKMade(shooter: player)
        case .ownGoal:   store.recordOwnGoal(player: player)
        default: break
        }
        activeQuickEvent = nil
    }

    private func confirmShot(onTarget: Bool) {
        guard let player = pendingPlayer else { return }
        store.recordShot(shooter: player, onTarget: onTarget, isPenalty: pendingShotIsPenalty)
        pendingPlayer = nil; pendingShotIsPenalty = false
    }

    private func confirmCard(type: CardType) {
        if let player = pendingPlayer { store.recordCard(player: player, card: type) }
        pendingPlayer = nil
    }

    // MARK: - Substitution

    private func attemptSwap(fieldPlayer: Player, benchPlayer: Player) -> Bool {
        store.refreshElapsedFromClock()
        store.pushUndo()
        if let index = store.onFieldLineupIDs.firstIndex(of: fieldPlayer.id) {
            store.onFieldLineupIDs[index] = benchPlayer.id
        } else {
            store.onFieldLineupIDs.append(benchPlayer.id)
        }
        store.onFieldIDs.remove(fieldPlayer.id)
        store.onFieldIDs.insert(benchPlayer.id)
        if benchPlayer.position == .gk, store.activeGoalkeeper()?.id == fieldPlayer.id {
            store.promoteGoalkeeper(benchPlayer.id)
        }
        store.markPlayerSecondsBaseline()
        return true
    }

    // MARK: - Timer State Machine

    private var primaryControlTitle: String {
        if store.matchEnded { return "Match Ended" }
        if !store.isActive { return "Start Game" }       // State 1
        if store.isRunning { return "Pause" }             // States 2, 5
        return "Resume"                                    // States 3, 4, 6
    }

    // MARK: - Period time

    /// "TIME", "12:34 LEFT", or "+0:45 STOPPAGE"
    private var timeCaption: String {
        guard store.isActive, !store.matchEnded, let left = store.periodSecondsRemaining else { return "TIME" }
        let m = abs(left) / 60, s = abs(left) % 60
        let clock = String(format: "%d:%02d", m, s)
        return left >= 0 ? "\(clock) LEFT" : "+\(clock) STOPPAGE"
    }

    private var timeCaptionIsOver: Bool {
        (store.periodSecondsRemaining ?? 1) < 0 && store.isActive && !store.matchEnded
    }

    private var periodTimeUpBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.periodName.prefix(1).uppercased() + store.periodName.dropFirst()) time is up")
                    .font(.system(size: 15, weight: .semibold))
                Text("Clock keeps running for stoppage.")
                    .font(.system(size: 12))
                    .opacity(0.7)
            }
            Spacer()
            Button("Keep") {
                store.periodTimeUp = false
            }
            .font(.system(size: 14, weight: .medium))
            .opacity(0.8)
            Button {
                haptic(.medium)
                store.pauseGame()
                if store.isFinalPeriod {
                    store.endMatchFreeze()
                    showingEndSheet = true
                } else {
                    store.endPeriod()
                }
            } label: {
                Text(store.isFinalPeriod ? "End Match" : (store.periodCount == 4 ? "End \(store.periodName)" : "Halftime"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(GoStatsTheme.textPrimary)
                .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        )
    }

    private func handleStartPause() {
        guard !store.matchEnded else { return }
        haptic(.light)

        if store.isRunning {
            // Pause the clock first
            store.pauseGame()

            if !isSecondHalf {
                // 1st half (State 2 -> show Pause/Halftime dialog)
                showPauseOptions = true
            }
            // 2nd half (State 5 -> just pause, no dialog. State 6.)
        } else {
            // Resume or Start (States 1, 3, 4, 6 -> start clock)
            store.startGame()

            // Start Live Activity on first start if not already active
            if !LiveActivityManager.shared.isActive {
                let teamName = store.liveActivityTeamName.isEmpty
                    ? (teamStore.teams.first(where: { $0.id == teamID })?.name ?? "Home")
                    : store.liveActivityTeamName
                LiveActivityManager.shared.startActivity(
                    teamName: teamName,
                    opponentName: store.liveActivityOpponent.isEmpty ? "Opponent" : store.liveActivityOpponent
                )
            }
        }
    }

    private func handleVoiceCommand(_ command: VoiceCommand) {
        switch command {
        case .goal(let scorer, let assist):
            store.recordGoal(scorer: scorer, assist: assist)
            let assistText = assist.map { " (assist: \(store.displayName(for: $0)))" } ?? ""
            voiceService.showToast("Goal -- \(store.displayName(for: scorer))\(assistText)")
        case .save(let keeper):
            store.recordKeeperSave()
            voiceService.showToast("Save -- \(store.displayName(for: keeper))")
        case .conceded(let keeper):
            store.recordKeeperConceded()
            voiceService.showToast("Conceded -- \(store.displayName(for: keeper))")
        case .card(let player):
            store.recordCard(player: player, card: .yellow)
            voiceService.showToast("Card -- \(store.displayName(for: player))")
        case .substitution(let playerOn, let playerOff):
            _ = attemptSwap(fieldPlayer: playerOff, benchPlayer: playerOn)
            voiceService.showToast("Sub -- \(store.displayName(for: playerOn)) for \(store.displayName(for: playerOff))")
        }
    }

    // MARK: - Haptics

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        Haptics.impact(style) // respects Settings → Haptics
    }

    // MARK: - Substitution Suggestions

    private func checkForSubSuggestions(minute: Int) {
        guard suggestionBanner == nil else { return }

        let winning = store.goalsFor > store.goalsAgainst
        let drawing = store.goalsFor == store.goalsAgainst
        let losing = store.goalsFor < store.goalsAgainst
        let half = store.hasSplitHalf ? 2 : 1

        let benchIDs = Set(store.players.map(\.id)).subtracting(store.onFieldIDs)

        for playerID in benchIDs {
            guard !dismissedSuggestionPlayerIDs.contains(playerID) else { continue }
            guard let profile = SubstitutionPatternStore.shared.profile(for: playerID),
                  profile.matchesCurrentSituation(minute: minute, winning: winning, drawing: drawing, losing: losing, half: half),
                  let player = store.players.first(where: { $0.id == playerID })
            else { continue }

            let posLabel = profile.mostCommonPosition ?? player.position.rawValue
            let banner = SubSuggestionBanner(
                player: player,
                position: posLabel,
                matchCount: profile.totalSubEvents
            )

            withAnimation(.spring(response: 0.4)) {
                suggestionBanner = banner
            }

            // Auto-dismiss after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [self] in
                if self.suggestionBanner?.player.id == player.id {
                    withAnimation { self.suggestionBanner = nil }
                }
            }
            return // Only show one at a time
        }
    }

    private func suggestionBannerView(_ banner: SubSuggestionBanner) -> some View {
        HStack(spacing: 10) {
            Text("\u{1F4A1}")
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.displayName(for: banner.player)) usually comes on around now (\(banner.position))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "1a1a1a"))
                Text("\(banner.matchCount) matches")
                    .font(.system(size: 11))
                    .foregroundStyle(GoStatsTheme.textMuted)
            }

            Spacer()

            Button {
                // Apply: open sub flow with this player pre-selected
                withAnimation { suggestionBanner = nil }
                showSubSheet = true
            } label: {
                Text("Apply")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "1a1a1a"))
            }

            Button {
                dismissedSuggestionPlayerIDs.insert(banner.player.id)
                withAnimation { suggestionBanner = nil }
            } label: {
                Text("Dismiss")
                    .font(.system(size: 13))
                    .foregroundStyle(GoStatsTheme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct SubSuggestionBanner {
    let player: Player
    let position: String
    let matchCount: Int
}

// MARK: - Substitution Sheet

private struct SubstitutionSheet: View {
    @ObservedObject var store: MatchStore
    let onSwap: (Player, Player) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayer: Player? = nil
    @State private var selectedIsField: Bool = false

    private var onField: [Player] { store.onFieldPlayers }
    private var bench: [Player] {
        let ids = Set(onField.map { $0.id })
        return store.players.filter { !ids.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("On Field").font(.headline).padding(.horizontal)
                        FieldView1443(
                            store: store,
                            selectedPlayerID: selectedIsField ? selectedPlayer?.id : nil,
                            onSelectPlayer: { handleTap(player: $0, isField: true) }
                        )
                        .frame(height: 320).padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bench").font(.headline).padding(.horizontal)
                        if bench.isEmpty {
                            Text("No bench players available.")
                                .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(bench) { player in
                                    Button { handleTap(player: player, isField: false) } label: {
                                        BenchPlayerTile(player: player, isSelected: selectedPlayer?.id == player.id, subtitle: positionSubtitle(for: player))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Substitution")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }

    private func handleTap(player: Player, isField: Bool) {
        if let sel = selectedPlayer, selectedIsField != isField {
            let f = selectedIsField ? sel : player
            let b = selectedIsField ? player : sel
            if onSwap(f, b) { selectedPlayer = nil; selectedIsField = false }
            return
        }
        selectedPlayer = player; selectedIsField = isField
    }

    private func positionSubtitle(for player: Player) -> String {
        if let sec = player.secondaryPosition { return "\(player.position.rawValue) / \(sec.rawValue)" }
        return player.position.rawValue
    }
}

private struct BenchPlayerTile: View {
    let player: Player; let isSelected: Bool; let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(GoStatsTheme.controlGray.opacity(0.12))
                        .overlay(Circle().stroke(GoStatsTheme.controlGray.opacity(0.25), lineWidth: 1))
                    Text("\(player.number)")
                        .font(.custom("DM Mono", size: 13))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                }
                .frame(width: 34, height: 34)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? GoStatsTheme.textPrimary : GoStatsTheme.textMuted.opacity(0.6))
            }
            Text(player.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(GoStatsTheme.textMuted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .stroke(isSelected ? GoStatsTheme.textPrimary.opacity(0.4) : GoStatsTheme.stroke.opacity(0.25), lineWidth: 1)
        )
    }
}
