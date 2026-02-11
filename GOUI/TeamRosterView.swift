import SwiftUI
import UniformTypeIdentifiers

struct TeamRosterView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @Binding var incomingRosterURL: URL?

    @State private var showingAddPlayer = false
    @State private var editingPlayer: Player? = nil
    @State private var searchText: String = ""
    @State private var selectedFilter: RosterFilter = .all
    @State private var displayedPlayers: [Player] = []
    @State private var refreshTask: Task<Void, Never>? = nil
    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var showingImportPicker = false
    @State private var importedPreview: RosterExport? = nil
    @State private var rosterErrorMessage: String? = nil
    @State private var conflictQueue: [Player] = []
    @State private var pendingConflict: Player? = nil
    @State private var isReplacingRoster = false
    @State private var showProximityShare = false
    @StateObject private var proximityShare = RosterProximityShareService()

    private let sport = SportDefinition.current

    private var teamIndex: Int? {
        teamStore.teams.firstIndex(where: { $0.id == teamID })
    }

    private var team: Team? {
        guard let idx = teamIndex else { return nil }
        return teamStore.teams[idx]
    }

    var body: some View {
        let _ = DebugRenderLogger.log("RosterView", enabled: DebugSettings.renderCountsEnabled)
        NavigationStack {
            rosterContent
            .navigationTitle(team?.name ?? "Roster")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            shareRoster()
                        } label: {
                            Label("Share Roster (AirDrop)", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            startProximityShare()
                        } label: {
                            Label("Share Roster Nearby", systemImage: "dot.radiowaves.left.and.right")
                        }

                        Button {
                            showingImportPicker = true
                        } label: {
                            Label("Import Roster", systemImage: "square.and.arrow.down")
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
            .onAppear {
                refreshPlayers()
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
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.goUIRoster, .json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importRoster(from: url)
                case .failure(let error):
                    rosterErrorMessage = error.localizedDescription
                }
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
            .sheet(isPresented: $showProximityShare, onDismiss: {
                proximityShare.stop()
            }) {
                proximityShareSheet
            }
        }
    }

    private var proximityShareSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Nearby Roster Share")
                    .font(.title3.weight(.semibold))
                Text("This uses local peer discovery over Bluetooth/Wi-Fi and encrypted transfer. Bring both devices close together.")
                    .foregroundStyle(.secondary)

                Text(proximityShare.status)
                    .font(.callout.weight(.medium))

                if let payload = proximityShare.receivedPayload {
                    Divider()
                    Text("Received Team: \(payload.teamName)")
                        .font(.headline)
                    Text("Players: \(payload.players.count)")
                        .foregroundStyle(.secondary)

                    Button("Import Received Roster") {
                        importReceivedRoster(payload)
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary))
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("Share Roster")
            .navigationBarTitleDisplayMode(.inline)
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
        GlassCard(level: .raised) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Roster")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("\(team?.players.count ?? 0) players")
                            .font(.footnote)
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    Spacer()
                    Button {
                        showingAddPlayer = true
                    } label: {
                        Label("Add Player", systemImage: "plus")
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary))
                }
            }
        }
    }

    private var rosterFilters: some View {
        GlassCard(level: .surface) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Filters")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                Picker("Roster Filter", selection: $selectedFilter) {
                    Text("All").tag(RosterFilter.all)
                    Text("Starters").tag(RosterFilter.starters)
                    if sport.supportsGoalie {
                        Text("Goalies").tag(RosterFilter.goalies)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var emptyState: some View {
        GlassCard(level: .surface) {
            VStack(alignment: .leading, spacing: 6) {
                Text("No players yet")
                    .font(.headline)
                Text("Tap “Add Player” to build your roster.")
                    .foregroundStyle(.secondary)
            }
        }
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

    private func shareRoster() {
        guard let team else { return }
        do {
            let url = try RosterTransferService.exportFile(for: team)
            shareSheetPayload = ShareSheetPayload(items: [url])
        } catch {
            rosterErrorMessage = error.localizedDescription
        }
    }

    private func startProximityShare() {
        guard let team else { return }
        proximityShare.startSharing(RosterSharePayload(team: team))
        showProximityShare = true
    }

    private func importReceivedRoster(_ payload: RosterSharePayload) {
        let players = payload.players.map {
            Player(
                id: $0.id,
                name: $0.name,
                number: $0.jerseyNumber,
                position: $0.position,
                isGoalie: $0.isGoalie
            )
        }
        importedPreview = RosterExport(team: Team(name: payload.teamName, players: players, startingOnFieldIDs: payload.players.filter(\.isStarter).map(\.id)))
        showProximityShare = false
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
                            .fill(GoStatsTheme.primary)
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
                                        .fill(GoStatsTheme.primary.opacity(0.18))
                                )
                                .foregroundStyle(GoStatsTheme.primary)
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
                        .foregroundStyle(GoStatsTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(GoStatsTheme.primary.opacity(0.18))
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
            Form {
                Section("Player") {
                    TextField("Name", text: $name)
                    if !isNameValid {
                        Text("Name is required.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)
                    if !isNumberValid {
                        Text("Number must be between 0 and 99.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if sport.supportsPositions {
                        Picker("Primary Position", selection: $position) {
                            ForEach(Position.rosterPositions) { pos in
                                Text(pos.rawValue).tag(pos)
                            }
                        }
                        .onChange(of: position) { _, newValue in
                            positionName = newValue.rawValue
                            if sport.supportsGoalie {
                                isGoalie = newValue == .gk
                            }
                        }

                        Picker("Secondary Position", selection: $secondaryPosition) {
                            Text("None").tag(Position?.none)
                            ForEach(Position.rosterPositions) { pos in
                                Text(pos.rawValue).tag(Optional(pos))
                            }
                        }
                    } else {
                        TextField("Position (optional)", text: $positionName)
                    }

                    if sport.supportsGoalie {
                        Toggle("Goalie", isOn: $isGoalie)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
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
                    .disabled(!isFormValid)
                }
            }
        }
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
