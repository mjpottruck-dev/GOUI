import SwiftUI
import UniformTypeIdentifiers

struct TeamRosterView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @Binding var incomingRosterURL: URL?

    @State private var showingAddPlayer = false
    @State private var editingPlayer: Player? = nil
    @State private var showAIImport = false
    @State private var searchText: String = ""
    @State private var selectedFilter: RosterFilter = .all
    @State private var displayedPlayers: [Player] = []
    @State private var refreshTask: Task<Void, Never>? = nil
    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var importedPreview: RosterExport? = nil
    @State private var rosterErrorMessage: String? = nil
    @State private var conflictQueue: [Player] = []
    @State private var pendingConflict: Player? = nil
    @State private var isReplacingRoster = false
    @StateObject private var sharingService = RosterSharingService()
    @State private var rippleActive = false

    private let sport = SportDefinition.current

    private var teamIndex: Int? {
        teamStore.teams.firstIndex(where: { $0.id == teamID })
    }

    private var team: Team? {
        guard let idx = teamIndex else { return nil }
        return teamStore.teams[idx]
    }

    /// Whether the share overlay should be visible
    private var showShareOverlay: Bool {
        switch sharingService.state {
        case .idle, .cancelled:
            return false
        case .searching, .peerFound, .sending, .sent, .failed,
             .receivingInvite, .connecting, .received:
            return true
        }
    }

    var body: some View {
        let _ = DebugRenderLogger.log("RosterView", enabled: DebugSettings.renderCountsEnabled)
        NavigationStack {
            ZStack {
                rosterContent

                if showShareOverlay {
                    shareOverlay
                        .transition(.opacity)
                }
            }
            .navigationTitle(team?.name ?? "Roster")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            guard let team else { return }
                            sharingService.startSharing(team: team)
                        } label: {
                            Label("Share Roster", systemImage: "dot.radiowaves.left.and.right")
                        }

                        Button {
                            if Paywall.require(.rosterImport) { showAIImport = true }
                        } label: {
                            Label("Import Roster via AI", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView { newPlayer in
                    addPlayer(newPlayer)
                }
            }
            .sheet(item: $editingPlayer) { player in
                EditPlayerSheet(player: player, sport: sport) { updated in
                    updatePlayer(updated)
                }
            }
            .sheet(isPresented: $showAIImport) {
                AIRosterImportView(teamStore: teamStore, teamID: teamID)
            }
            .onAppear {
                refreshPlayers()
                sharingService.startListening()
            }
            .onDisappear {
                sharingService.stopListening()
            }
            .onChange(of: sharingService.state) { _, newState in
                switch newState {
                case .searching, .connecting:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        rippleActive = true
                    }
                default:
                    rippleActive = false
                }
            }
            .onChange(of: sharingService.receivedRoster?.teamName) { _, newName in
                guard let roster = sharingService.receivedRoster else { return }
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
                sharingService.sendAck()
                sharingService.receivedRoster = nil
            }
            .onChange(of: searchText) { _, _ in
                refreshPlayers()
            }
            .onChange(of: selectedFilter) { _, _ in
                refreshPlayers()
            }
            .onChange(of: teamStore.teams) { _, _ in
                refreshPlayers()
            }
            .onChange(of: incomingRosterURL) { _, newValue in
                guard let url = newValue else { return }
                importRoster(from: url)
                incomingRosterURL = nil
            }
            .alert("Import Error", isPresented: importErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(rosterErrorMessage ?? "")
            }
            .confirmationDialog(
                "Import Roster",
                isPresented: importPreviewPresented,
                titleVisibility: .visible
            ) {
                Button("Merge with Current Team") {
                    isReplacingRoster = false
                    beginImport()
                }
                Button("Replace Current Roster", role: .destructive) {
                    isReplacingRoster = true
                    beginImport()
                }
                Button("Cancel", role: .cancel) {
                    importedPreview = nil
                }
            } message: {
                if let preview = importedPreview {
                    Text("Team: \(preview.team.name)\nPlayers: \(preview.playerCount)")
                }
            }
            .alert(
                "Duplicate Number Found",
                isPresented: conflictAlertPresented,
                presenting: pendingConflict
            ) { player in
                Button("Replace") {
                    resolveConflict(for: player, replace: true)
                }
                Button("Skip") {
                    resolveConflict(for: player, replace: false)
                }
            } message: { player in
                Text("A player with #\(player.number) already exists. Replace with \(player.name)?")
            }
            .sheet(item: $shareSheetPayload) { payload in
                ShareSheet(activityItems: payload.items)
            }
        }
    }

    private var rosterContent: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    rosterHeader

                    rosterFilters

                    if displayedPlayers.isEmpty {
                        emptyState
                    } else {
                        ForEach(displayedPlayers) { player in
                            PlayerRowView(
                                player: player,
                                isStarter: team?.startingOnFieldIDs.contains(player.id) == true,
                                sport: sport
                            )
                            .equatable()
                            .onTapGesture {
                                editingPlayer = player
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deletePlayer(player)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var importErrorPresented: Binding<Bool> {
        Binding(
            get: { rosterErrorMessage != nil },
            set: { _ in rosterErrorMessage = nil }
        )
    }

    private var importPreviewPresented: Binding<Bool> {
        Binding(
            get: { importedPreview != nil },
            set: { isPresented in
                if !isPresented { importedPreview = nil }
            }
        )
    }

    private var conflictAlertPresented: Binding<Bool> {
        Binding(
            get: { pendingConflict != nil },
            set: { isPresented in
                if !isPresented { pendingConflict = nil }
            }
        )
    }

    private var rosterHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Roster")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                Text("\(team?.players.count ?? 0) players")
                    .font(.system(size: 13))
                    .foregroundStyle(GoStatsTheme.textMuted)
            }
            Spacer()
            Button {
                showingAddPlayer = true
            } label: {
                Label("Add Player", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                            .fill(GoStatsTheme.textPrimary)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(GoStatsTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
        )
    }

    private var rosterFilters: some View {
        VStack(alignment: .leading, spacing: 8) {
            GoStatsTheme.sectionHeader("FILTERS")

            Picker("Roster Filter", selection: $selectedFilter) {
                Text("All").tag(RosterFilter.all)
                Text("Starters").tag(RosterFilter.starters)
                if sport.supportsGoalie {
                    Text("Goalies").tag(RosterFilter.goalies)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(GoStatsTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3")
                .font(.system(size: 28))
                .foregroundStyle(GoStatsTheme.emptyStateColor)
            Text("No players yet. Tap Add Player to start.")
                .font(.system(size: 13))
                .foregroundStyle(GoStatsTheme.emptyStateColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func refreshPlayers() {
        refreshTask?.cancel()
        let players = team?.players ?? []
        let starters = Set(team?.startingOnFieldIDs ?? [])
        let filter = selectedFilter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshTask = Task.detached { [sport] in
            let filtered = players.filter { player in
                if !query.isEmpty {
                    let match = player.name.localizedCaseInsensitiveContains(query)
                        || "\(player.number)".contains(query)
                    if !match { return false }
                }
                switch filter {
                case .all:
                    return true
                case .starters:
                    return starters.contains(player.id)
                case .goalies:
                    return sport.supportsGoalie && player.derivedIsGoalie
                }
            }

            let sorted = filtered.sorted(by: sortPlayers)
            await MainActor.run {
                displayedPlayers = sorted
            }
        }
    }

    private func addPlayer(_ player: Player) {
        teamStore.addPlayer(player, to: teamID)
    }

    private func updatePlayer(_ player: Player) {
        teamStore.updatePlayer(player, on: teamID)
    }

    private func deletePlayer(_ player: Player) {
        teamStore.deletePlayer(player, from: teamID)
    }

    // MARK: - Share Overlay

    private var shareOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                switch sharingService.state {
                case .sent:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.green)
                    Text("Roster Shared Successfully!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                case .received:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.green)
                    Text("Roster Received!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                case .receivingInvite(let peerName):
                    GlassCard(level: .focus) {
                        VStack(spacing: 16) {
                            Image(systemName: "person.wave.2.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.teal)
                            Text("\(peerName) wants to share a roster")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(GoStatsTheme.text)
                                .multilineTextAlignment(.center)
                            HStack(spacing: 12) {
                                Button { sharingService.declineInvitation() } label: {
                                    Text("Decline").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassPillButtonStyle(fill: Color(.systemGray3)))
                                Button { sharingService.acceptInvitation() } label: {
                                    Text("Accept").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.teal))
                            }
                        }
                    }
                    .frame(maxWidth: 320)

                case .failed(let message):
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

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
                    Text(shareOverlayStatusText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }

                Spacer()

                if case .searching = sharingService.state {
                    shareCancelButton
                } else if case .peerFound = sharingService.state {
                    shareCancelButton
                } else if case .sending = sharingService.state {
                    shareCancelButton
                } else if case .connecting = sharingService.state {
                    shareCancelButton
                }

                Spacer().frame(height: 30)
            }
        }
    }

    private var shareOverlayStatusText: String {
        switch sharingService.state {
        case .searching: return "Searching for nearby devices..."
        case .peerFound(let name): return "Found \(name)... sending"
        case .sending: return "Sending roster..."
        case .connecting: return "Receiving roster..."
        default: return ""
        }
    }

    private var shareCancelButton: some View {
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

    private func importRoster(from url: URL) {
        do {
            importedPreview = try RosterTransferService.importRoster(from: url)
        } catch {
            rosterErrorMessage = error.localizedDescription
        }
    }

    private func beginImport() {
        guard let incoming = importedPreview,
              let teamIndex = teamStore.teams.firstIndex(where: { $0.id == teamID }) else {
            return
        }

        if isReplacingRoster {
            var updated = teamStore.teams[teamIndex]
            updated.name = incoming.team.name
            updated.players = incoming.team.players
            updated.fieldSize = incoming.team.fieldSize
            updated.primaryFormation = incoming.team.primaryFormation
            updated.startingOnFieldIDs = incoming.team.startingOnFieldIDs.filter { id in
                incoming.team.players.contains(where: { $0.id == id })
            }
            updated.primaryGoalkeeperID = incoming.team.primaryGoalkeeperID
            updated.secondaryGoalkeeperID = incoming.team.secondaryGoalkeeperID
            updated.thirdGoalkeeperID = incoming.team.thirdGoalkeeperID
            teamStore.updateTeam(updated)
            importedPreview = nil
            return
        }

        conflictQueue = incoming.team.players
        importedPreview = nil
        processNextConflictOrInsert()
    }

    private func processNextConflictOrInsert() {
        guard let teamIndex = teamStore.teams.firstIndex(where: { $0.id == teamID }) else {
            conflictQueue = []
            pendingConflict = nil
            return
        }

        while !conflictQueue.isEmpty {
            let next = conflictQueue.removeFirst()
            if teamStore.teams[teamIndex].players.contains(where: { $0.number == next.number }) {
                pendingConflict = next
                return
            }
            teamStore.addPlayer(next, to: teamID)
        }

        pendingConflict = nil
    }

    private func resolveConflict(for incomingPlayer: Player, replace: Bool) {
        defer {
            pendingConflict = nil
            processNextConflictOrInsert()
        }
        guard replace,
              let teamIndex = teamStore.teams.firstIndex(where: { $0.id == teamID }),
              let existingIndex = teamStore.teams[teamIndex].players.firstIndex(where: { $0.number == incomingPlayer.number }) else {
            return
        }

        var updatedTeam = teamStore.teams[teamIndex]
        let existing = updatedTeam.players[existingIndex]
        var replacement = incomingPlayer
        replacement.id = existing.id
        updatedTeam.players[existingIndex] = replacement
        teamStore.updateTeam(updatedTeam)
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }
}

private enum RosterFilter: Hashable {
    case all
    case starters
    case goalies
}

private func sortPlayers(_ a: Player, _ b: Player) -> Bool {
    let order: [Position: Int] = [
        .gk: 0, .cb: 1, .rb: 2, .lb: 3, .rwb: 4, .lwb: 5,
        .cdm: 6, .cm: 7, .cam: 8, .rm: 9, .lm: 10,
        .rw: 11, .lw: 12, .st: 13, .cf: 14
    ]
    let pa = order[a.position] ?? 99
    let pb = order[b.position] ?? 99
    if pa != pb { return pa < pb }
    return a.number < b.number
}

private struct PlayerRowView: View, Equatable {
    let player: Player
    let isStarter: Bool
    let sport: SportDefinition

    static func == (lhs: PlayerRowView, rhs: PlayerRowView) -> Bool {
        lhs.player.id == rhs.player.id
            && lhs.player.name == rhs.player.name
            && lhs.player.number == rhs.player.number
            && lhs.player.positionName == rhs.player.positionName
            && lhs.player.isGoalie == rhs.player.isGoalie
            && lhs.isStarter == rhs.isStarter
    }

    var body: some View {
        GlassCard(level: .surface) {
            HStack(spacing: 12) {
                Text("\(player.number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(GoStatsTheme.textPrimary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(player.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)

                        if isStarter {
                            Text("Starter")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "f0f0f0"))
                                )
                                .foregroundStyle(GoStatsTheme.textPrimary)
                        }
                    }

                    if let positionLabel = player.displayPosition(for: sport) {
                        Text(positionLabel)
                            .font(.subheadline)
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                Spacer()

                if sport.supportsGoalie, player.derivedIsGoalie {
                    Label("Goalie", systemImage: "shield.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color(hex: "f0f0f0"))
                        )
                }
            }
        }
    }
}

private struct EditPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var numberText: String
    @State private var position: Position
    @State private var secondaryPosition: Position?
    @State private var positionName: String
    @State private var isGoalie: Bool
    @State private var notes: String

    let playerID: UUID
    let sport: SportDefinition
    let onSave: (Player) -> Void

    init(player: Player, sport: SportDefinition, onSave: @escaping (Player) -> Void) {
        self._name = State(initialValue: player.name)
        self._numberText = State(initialValue: player.jersey.isEmpty ? "\(player.number)" : player.jersey)
        self._position = State(initialValue: player.position)
        self._secondaryPosition = State(initialValue: player.secondaryPosition)
        self._positionName = State(initialValue: player.positionName ?? player.position.rawValue)
        self._isGoalie = State(initialValue: player.isGoalie ?? (player.position == .gk))
        self._notes = State(initialValue: player.notes ?? "")
        self.playerID = player.id
        self.sport = sport
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Player avatar
                        ZStack {
                            Circle()
                                .fill(GoStatsTheme.textPrimary)
                                .frame(width: 80, height: 80)
                            Text(numberText.isEmpty ? "#" : numberText)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 8)

                        // Name + Number card
                        VStack(alignment: .leading, spacing: 16) {
                            editField(label: "PLAYER NAME", icon: "person") {
                                TextField("Full name", text: $name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                            if !isNameValid {
                                Text("Name is required.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                                    .padding(.top, -10)
                            }

                            Divider()

                            editField(label: "JERSEY NUMBER", icon: "number") {
                                TextField("0–99", text: $numberText)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                    .keyboardType(.numberPad)
                            }
                            if !isNumberValid {
                                Text("Number must be between 0 and 99.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                                    .padding(.top, -10)
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(editCardBackground)

                        // Position card
                        if sport.supportsPositions {
                            VStack(alignment: .leading, spacing: 16) {
                                editField(label: "PRIMARY POSITION", icon: "mappin.and.ellipse") {
                                    Picker("", selection: $position) {
                                        ForEach(Position.rosterPositions) { pos in
                                            Text(pos.rawValue).tag(pos)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(GoStatsTheme.textPrimary)
                                }
                                .onChange(of: position) { _, newValue in
                                    positionName = newValue.rawValue
                                    if sport.supportsGoalie {
                                        isGoalie = newValue == .gk
                                    }
                                }

                                Divider()

                                editField(label: "SECONDARY POSITION", icon: "arrow.triangle.swap") {
                                    Picker("", selection: $secondaryPosition) {
                                        Text("None").tag(Position?.none)
                                        ForEach(Position.rosterPositions) { pos in
                                            Text(pos.rawValue).tag(Optional(pos))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(GoStatsTheme.textPrimary)
                                }

                                if sport.supportsGoalie {
                                    Divider()
                                    HStack {
                                        Image(systemName: "shield.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                            .frame(width: 20)
                                        Text("Goalkeeper")
                                            .font(.system(size: 10, weight: .semibold))
                                            .tracking(0.5)
                                            .textCase(.uppercase)
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                        Spacer()
                                        Toggle("", isOn: $isGoalie)
                                            .labelsHidden()
                                            .tint(GoStatsTheme.textPrimary)
                                    }
                                }
                            }
                            .padding(GoStatsTheme.cardPadding)
                            .background(editCardBackground)
                        }

                        // Notes card
                        VStack(alignment: .leading, spacing: 8) {
                            editField(label: "NOTES", icon: "note.text") {
                                TextField("Add notes...", text: $notes, axis: .vertical)
                                    .font(.system(size: 15))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                    .lineLimit(3...6)
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(editCardBackground)

                        // Save button
                        Button {
                            savePlayer()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                        .fill(GoStatsTheme.textPrimary.opacity(isFormValid ? 1.0 : 0.4))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isFormValid)

                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "aaaaaa"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func editField<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.textMuted)
                    .frame(width: 16)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(GoStatsTheme.textMuted)
            }
            content()
        }
    }

    private var editCardBackground: some View {
        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
            .fill(Color.white)
            .shadow(color: GoStatsTheme.cardShadowColor,
                    radius: GoStatsTheme.cardShadowRadius,
                    x: 0, y: GoStatsTheme.cardShadowY)
    }

    private func savePlayer() {
        let trimmedNumber = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
        let number = Int(trimmedNumber) ?? 0
        let jersey = trimmedNumber.isEmpty ? "\(number)" : trimmedNumber
        let resolvedPositionName = positionName.isEmpty ? position.rawValue : positionName
        let updated = Player(
            id: playerID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            number: number,
            jersey: jersey,
            position: position,
            secondaryPosition: secondaryPosition,
            positionName: resolvedPositionName,
            isGoalie: sport.supportsGoalie ? isGoalie : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(updated)
        dismiss()
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isNumberValid: Bool {
        let trimmed = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed) else { return false }
        return (0...99).contains(value)
    }

    private var isFormValid: Bool {
        isNameValid && isNumberValid
    }
}
