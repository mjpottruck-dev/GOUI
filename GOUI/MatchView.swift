import SwiftUI

struct MatchView: View {

    @ObservedObject var store: MatchStore
    @ObservedObject var clipStore: ClipStore
    var teamStore: TeamStore
    let teamID: UUID

    @Environment(\.scenePhase) private var scenePhase

    @State private var showingEndSheet = false
    @State private var showHaptics = true
    @State private var showFormationPicker = false
    @State private var showSplitSheet = false

    @State private var activeQuickEvent: EventType? = nil
    @State private var showFieldOverlay = false
    @State private var pendingScorer: Player? = nil
    @State private var pendingPlayer: Player? = nil
    @State private var pendingEventType: EventType? = nil
    @State private var showAssistPicker = false
    @State private var showShotDialog = false
    @State private var showCardDialog = false
    @State private var showSubSheet = false
    @State private var showPlayerPicker = false
    @State private var showAssistPickerSheet = false
    @State private var showHoleEntrySheet = false
    @State private var pendingHolePlayer: Player? = nil
    @State private var showTagPrompt = false
    @State private var pendingTaggedEvent: MatchEvent? = nil
    @State private var showTagClipSheet = false
    @State private var recordingError: String? = nil

    @StateObject private var videoCaptureService: VideoCaptureService

    private var resolvedFormation: Formation {
        store.formation ?? Formation.allCases.first!
    }

    init(store: MatchStore, clipStore: ClipStore, teamStore: TeamStore, teamID: UUID) {
        self.store = store
        self.clipStore = clipStore
        self.teamStore = teamStore
        self.teamID = teamID
        _videoCaptureService = StateObject(wrappedValue: VideoCaptureService(clipStore: clipStore))
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    scoreCard
                    controlRow
                    recordingCard
                    quickEventsTeam
                    quickEventsKeeper
                    fieldCard
                    MatchTimelineView(
                        events: store.events,
                        clipStore: clipStore,
                        teamStore: teamStore,
                        teamID: teamID
                    )

                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .overlay(fieldOverlay)
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { showingEndSheet = true }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showingEndSheet) {
            if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                EndMatchSheet(
                    store: store,
                    teamStore: teamStore,
                    teamID: teamID,
                    team: team,
                    formation: resolvedFormation
                )
            } else {
                NavigationStack {
                    VStack(spacing: 12) {
                        Text("Team not found")
                            .font(.headline)
                        Text("Go back and pick a team again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .navigationTitle("End Match")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .sheet(isPresented: $showFormationPicker) {
            FormationPickerSheet { formation in
                store.formation = formation
            }
        }
        .confirmationDialog("Shot Result", isPresented: $showShotDialog, titleVisibility: .visible) {
            Button("On Target") { confirmShot(onTarget: true) }
            Button("Off Target") { confirmShot(onTarget: false) }
            Button("Cancel", role: .cancel) {
                pendingPlayer = nil
                activeQuickEvent = nil
                pendingEventType = nil
            }
        }
        .confirmationDialog("Card", isPresented: $showCardDialog, titleVisibility: .visible) {
            Button(CardType.yellow.rawValue) { confirmCard(type: .yellow) }
            Button(CardType.red.rawValue) { confirmCard(type: .red) }
            Button("Cancel", role: .cancel) {
                pendingPlayer = nil
                activeQuickEvent = nil
                pendingEventType = nil
            }
        }
        .sheet(isPresented: $showSubSheet) {
            SubstitutionSheet(store: store, onSwap: attemptSwap)
        }
        .sheet(isPresented: $showSplitSheet) {
            SplitPeriodSheet(
                currentPeriodName: store.currentPeriodLabel(),
                nextPeriodName: store.nextPeriodLabel(),
                onAdvance: {
                    store.advancePeriodAndResume()
                },
                onKeepPaused: {}
            )
        }
        .sheet(isPresented: $showPlayerPicker) {
            if let eventType = pendingEventType {
                PlayerPickerSheet(eventType: eventType, store: store) { player in
                    handlePlayerSelection(player, for: eventType)
                }
            }
        }
        .sheet(isPresented: $showAssistPickerSheet, onDismiss: {
            if pendingScorer != nil {
                pendingScorer = nil
                pendingEventType = nil
            }
        }) {
            if let eventType = pendingEventType, let scorer = pendingScorer {
                PlayerFieldPicker(store: store, title: "Assist • \(eventType.label)") { player in
                    let event = store.recordEvent(eventType: eventType, primaryPlayer: scorer, secondaryPlayer: player)
                    handleEventRecorded(event)
                    pendingScorer = nil
                    pendingEventType = nil
                    showAssistPickerSheet = false
                }
            }
        }
        .sheet(isPresented: $showHoleEntrySheet) {
            if let player = pendingHolePlayer {
                GolfHoleEntrySheet(store: store, player: player) {
                    pendingHolePlayer = nil
                    pendingEventType = nil
                }
            }
        }
        .confirmationDialog("Tag clip for this event?", isPresented: $showTagPrompt, titleVisibility: .visible) {
            Button("Tag Clip") {
                showTagClipSheet = true
            }
            Button("Not Now", role: .cancel) {
                pendingTaggedEvent = nil
            }
        }
        .sheet(isPresented: $showTagClipSheet, onDismiss: {
            pendingTaggedEvent = nil
        }) {
            if let event = pendingTaggedEvent {
                ClipTaggingSheet(
                    clipStore: clipStore,
                    event: event,
                    gameID: store.currentMatchID,
                    players: store.players,
                    periodLabel: store.currentPeriodLabel(),
                    activeRecordingElapsed: videoCaptureService.elapsedTime
                )
            }
        }
        .onAppear { store.loadSampleIfEmpty() }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                store.refreshElapsedFromClock()
            }
            videoCaptureService.handleScenePhase(newValue)
        }
        .onChange(of: videoCaptureService.lastError) { _, newValue in
            recordingError = newValue
        }
        .alert("Recording Error", isPresented: Binding(get: { recordingError != nil }, set: { _ in recordingError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(recordingError ?? "")
        }
    }

    // MARK: - Cards

    private var scoreCard: some View {
        LiquidGlassContainer(material: .thinMaterial) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if store.sport.supportsTimer {
                        Button(action: handleStartPause) {
                            Text(primaryControlTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(GoStatsTheme.primary.opacity(0.95))
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    } else if store.sport.supportsPeriods {
                        Button(action: handleAdvancePeriod) {
                            Text("Next Set")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(GoStatsTheme.primary.opacity(0.95))
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.hasNextPeriod())
                    }

                    Spacer()

                    if store.sport.supportsPeriods || store.sport.supportsHoles {
                        Text(currentSegmentLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                HStack(alignment: .center) {
                    if store.sport.supportsTimer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.timeString)
                                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                                .foregroundStyle(GoStatsTheme.text)

                            Text("TIME")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }

                    if store.sport.supportsTeamScore {
                        Spacer()

                        Text("\(store.goalsFor)–\(store.goalsAgainst)")
                            .font(.system(size: 30, weight: .semibold, design: .monospaced))
                            .foregroundStyle(GoStatsTheme.text)
                    }
                }

                if !store.sport.supportsTeamScore {
                    individualScoreTable
                }
            }
        }
    }

    private var fieldCard: some View {
        Group {
            if store.sport.supportsCourtOverlay {
                LiquidGlassContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("FIELD")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)

                            Spacer()

                            if store.sport.supportsPositions {
                                Button(resolvedFormation.rawValue) {
                                    showFormationPicker = true
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)
                            }
                        }

                        FieldView1443(store: store)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }

    private var controlRow: some View {
        LiquidGlassContainer {
            HStack {
                Button {
                    if store.canUndo {
                        haptic(.medium)
                        store.undoLast()
                    } else {
                        Haptics.undoEmpty()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(
                    GlassPillButtonStyle(
                        fill: Color(red: 0.35, green: 0.48, blue: 0.57) // #5A7B91
                    )
                )
                .disabled(!store.canUndo)

                Spacer()
                if store.sport.supportsTeamScore, store.sport.supportsCourtOverlay {
                    Button {
                        haptic(.light)
                        showSubSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sub")
                        }
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary.opacity(0.95)))
                }
            }
        }
    }

    private var recordingCard: some View {
        LiquidGlassContainer {
            HStack(spacing: 12) {
                Circle()
                    .fill(videoCaptureService.isRecording ? Color.red : Color.gray.opacity(0.4))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(videoCaptureService.isRecording ? "Recording" : "Not Recording")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)

                    Text(recordingElapsedString)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                Spacer()

                Button {
                    if videoCaptureService.isRecording {
                        videoCaptureService.stopRecording()
                    } else {
                        videoCaptureService.startRecording(gameID: store.currentMatchID)
                    }
                } label: {
                    Text(videoCaptureService.isRecording ? "Stop" : "Record")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(videoCaptureService.isRecording ? Color.red.opacity(0.9) : GoStatsTheme.primary.opacity(0.95))
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var teamEventTypes: [EventType] {
        store.sport.eventTypes.filter { !$0.isGoalieOnly }
    }

    private var goalieEventTypes: [EventType] {
        guard store.sport.supportsGoalie else { return [] }
        return store.sport.eventTypes.filter { $0.isGoalieOnly }
    }

    private var recordingElapsedString: String {
        let totalSeconds = Int(videoCaptureService.elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Quick Events

    private var quickEventsTeam: some View {
        let eventTypes = teamEventTypes
        return LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK EVENTS — TEAM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(eventTypes) { eventType in
                        quickButton(eventType.label) {
                            startQuickEvent(eventType)
                        }
                    }
                }
            }
        }
    }

    private var quickEventsKeeper: some View {
        let eventTypes = goalieEventTypes
        return Group {
            if eventTypes.isEmpty {
                EmptyView()
            } else {
                LiquidGlassContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK EVENTS — GOALIE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(eventTypes) { eventType in
                                quickButton(eventType.label) {
                                    startQuickEvent(eventType)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            haptic(.light)
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary.opacity(0.95)))
    }

    private var fieldOverlay: some View {
        Group {
            if showFieldOverlay, let currentQuickEvent = activeQuickEvent, store.sport.supportsCourtOverlay {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()

                    VStack(spacing: 16) {
                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SELECT PLAYER")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text2)

                                Text("Tap a player on the field.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.text)
                            }
                        }
                        .padding(.horizontal, 16)

                        FieldView1443(store: store, onSelectPlayer: { player in
                            handleFieldSelection(player, for: currentQuickEvent)
                        })
                        .padding(.horizontal, 16)

                        Button {
                            showFieldOverlay = false
                            activeQuickEvent = nil
                            pendingEventType = nil
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .frame(maxWidth: 180)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 24)
                }
            }
            if showAssistPicker, let scorer = pendingScorer, store.sport.supportsCourtOverlay {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()

                    VStack(spacing: 16) {
                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SELECT PLAYER")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text2)

                                Text("Tap a player on the field.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.text)
                            }
                        }
                        .padding(.horizontal, 16)

                        FieldView1443(store: store, onSelectPlayer: { player in
                            if let eventType = pendingEventType {
                                let event = store.recordEvent(eventType: eventType, primaryPlayer: scorer, secondaryPlayer: player)
                                handleEventRecorded(event)
                            }
                            pendingScorer = nil
                            showAssistPicker = false
                            pendingEventType = nil
                        })
                        .padding(.horizontal, 16)

                        Button {
                            if let eventType = pendingEventType {
                                let event = store.recordEvent(eventType: eventType, primaryPlayer: scorer, secondaryPlayer: nil)
                                handleEventRecorded(event)
                            }
                            pendingScorer = nil
                            showAssistPicker = false
                            pendingEventType = nil
                        } label: {
                            Text("No Assist")
                                .frame(maxWidth: 180)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Quick Event Flow

    private func startQuickEvent(_ eventType: EventType) {
        pendingEventType = eventType
        if eventType.requiresPlayer {
            if store.sport.supportsCourtOverlay {
                activeQuickEvent = eventType
                showFieldOverlay = true
            } else {
                showPlayerPicker = true
            }
        } else {
            let event = store.recordEvent(eventType: eventType)
            handleEventRecorded(event)
            pendingEventType = nil
        }
    }

    private func handleFieldSelection(_ player: Player, for eventType: EventType) {
        showFieldOverlay = false
        handlePlayerSelection(player, for: eventType)
    }

    private func handlePlayerSelection(_ player: Player, for eventType: EventType) {
        pendingEventType = eventType
        switch eventType.uiAction {
        case .assist:
            pendingScorer = player
            if store.sport.supportsCourtOverlay {
                showAssistPicker = true
            } else {
                showAssistPickerSheet = true
            }
        case .shot:
            pendingPlayer = player
            showShotDialog = true
        case .shotPenalty:
            pendingPlayer = player
            showShotDialog = true
        case .card:
            pendingPlayer = player
            showCardDialog = true
        case .holeEntry:
            pendingHolePlayer = player
            showHoleEntrySheet = true
        case .direct:
            let event = store.recordEvent(eventType: eventType, primaryPlayer: player)
            handleEventRecorded(event)
            pendingEventType = nil
        }
        activeQuickEvent = nil
    }

    private func confirmShot(onTarget: Bool) {
        guard let player = pendingPlayer, let eventType = pendingEventType else { return }
        let event = store.recordEvent(eventType: eventType, primaryPlayer: player, shotOnTarget: onTarget)
        handleEventRecorded(event)
        pendingPlayer = nil
        pendingEventType = nil
    }

    private func confirmCard(type: CardType) {
        if let player = pendingPlayer, let eventType = pendingEventType {
            let event = store.recordEvent(eventType: eventType, primaryPlayer: player, cardType: type)
            handleEventRecorded(event)
        }
        pendingPlayer = nil
        pendingEventType = nil
    }

    private func handleEventRecorded(_ event: MatchEvent) {
        pendingTaggedEvent = event
        showTagPrompt = true
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
        if benchPlayer.position == .gk,
           store.activeGoalkeeper()?.id == fieldPlayer.id {
            store.promoteGoalkeeper(benchPlayer.id)
        }
        store.markPlayerSecondsBaseline()
        return true
    }

    // MARK: - Timer Controls

    private var primaryControlTitle: String {
        if store.isRunning {
            return "Pause"
        }
        if !store.hasNextPeriod(), store.secondsElapsed > 0 {
            return "End Match"
        }
        return "Start"
    }

    private func handleStartPause() {
        haptic(.light)
        if store.isRunning {
            store.pauseGame()
            if store.hasNextPeriod() {
                showSplitSheet = true
            } else {
                showingEndSheet = true
            }
        } else {
            store.startGame()
        }
    }

    private func handleAdvancePeriod() {
        haptic(.light)
        store.advancePeriodAndResume()
    }

    // MARK: - Haptics

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard showHaptics else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private var currentSegmentLabel: String {
        if store.sport.supportsHoles {
            return "Hole \(store.currentPeriodIndex + 1)"
        }
        return store.currentPeriodLabel()
    }

    private var individualScoreTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INDIVIDUAL \(store.sport.scoringRules.scoreLabel.uppercased())")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)

            ForEach(sortedPlayers) { player in
                HStack {
                    Text(store.displayName(for: player))
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text(individualScoreValue(for: player))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text)
                }
            }
        }
    }

    private func individualScoreValue(for player: Player) -> String {
        let statID = store.sport.scoringRules.primaryStatID
        return "\(player.statValue(for: statID))"
    }

    private var sortedPlayers: [Player] {
        store.players.sorted { ($0.number, $0.name) < ($1.number, $1.name) }
    }
}

private struct SubstitutionSheet: View {
    @ObservedObject var store: MatchStore
    let onSwap: (Player, Player) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayer: Player? = nil
    @State private var selectedIsField: Bool = false

    private var onField: [Player] {
        store.onFieldPlayers
    }

    private var bench: [Player] {
        let onFieldIDs = Set(onField.map { $0.id })
        return store.players.filter { !onFieldIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("On Field")
                            .font(.headline)
                            .padding(.horizontal)

                        FieldView1443(
                            store: store,
                            selectedPlayerID: selectedIsField ? selectedPlayer?.id : nil,
                            onSelectPlayer: { player in
                                handleTap(player: player, isField: true)
                            }
                        )
                        .frame(height: 320)
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bench")
                            .font(.headline)
                            .padding(.horizontal)

                        if bench.isEmpty {
                            Text("No bench players available.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: benchColumns, spacing: 12) {
                                ForEach(bench) { player in
                                    Button {
                                        handleTap(player: player, isField: false)
                                    } label: {
                                        BenchPlayerTile(
                                            player: player,
                                            isSelected: selectedPlayer?.id == player.id,
                                            subtitle: positionSubtitle(for: player)
                                        )
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var benchColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func handleTap(player: Player, isField: Bool) {
        if let selectedPlayer, selectedIsField != isField {
            let fieldPlayer = selectedIsField ? selectedPlayer : player
            let benchPlayer = selectedIsField ? player : selectedPlayer
            let success = onSwap(fieldPlayer, benchPlayer)
            if success {
                self.selectedPlayer = nil
                self.selectedIsField = false
            }
            return
        }

        selectedPlayer = player
        selectedIsField = isField
    }

    private func positionSubtitle(for player: Player) -> String {
        if store.sport.supportsPositions {
            if let secondary = player.secondaryPosition {
                return "\(player.position.rawValue) / \(secondary.rawValue)"
            }
            return player.position.rawValue
        }
        return player.positionName ?? "No Position"
    }
}

private struct BenchPlayerTile: View {
    let player: Player
    let isSelected: Bool
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(GoStatsTheme.teal.opacity(0.18))
                        .overlay(
                            Circle().stroke(GoStatsTheme.teal.opacity(0.32), lineWidth: 1)
                        )

                    Text("\(player.number)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text)
                }
                .frame(width: 34, height: 34)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? GoStatsTheme.teal : GoStatsTheme.text2.opacity(0.6))
            }

            Text(player.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)

            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(GoStatsTheme.text2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? GoStatsTheme.teal.opacity(0.4) : GoStatsTheme.stroke.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct SplitPeriodSheet: View {
    let currentPeriodName: String
    let nextPeriodName: String?
    let onAdvance: () -> Void
    let onKeepPaused: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(nextPeriodName == nil ? "Resume match?" : "Start next period?")
                    .font(.title2.weight(.semibold))

                Text(nextPeriodDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button {
                        onAdvance()
                        dismiss()
                    } label: {
                        Text(nextPeriodButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary.opacity(0.95)))

                    Button {
                        onKeepPaused()
                        dismiss()
                    } label: {
                        Text("Keep Paused")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(scheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .padding(24)
            .navigationTitle("Break")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var nextPeriodDescription: String {
        if let nextPeriodName {
            return "End \(currentPeriodName) and resume play in \(nextPeriodName)."
        }
        return "Resume play when you're ready."
    }

    private var nextPeriodButtonTitle: String {
        if let nextPeriodName {
            return "Start \(nextPeriodName)"
        }
        return "Resume"
    }
}
