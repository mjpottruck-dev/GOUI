import SwiftUI

struct TeamRosterView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var showingAddPlayer = false
    @State private var editingPlayer: Player? = nil
    @State private var searchText: String = ""
    @State private var selectedFilter: RosterFilter = .all
    @State private var displayedPlayers: [Player] = []
    @State private var refreshTask: Task<Void, Never>? = nil

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
            .navigationTitle(team?.name ?? "Roster")
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
        }
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
        .equatable()
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
        self._isGoalie = State(initialValue: player.isGoalie ?? player.position == .gk)
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
