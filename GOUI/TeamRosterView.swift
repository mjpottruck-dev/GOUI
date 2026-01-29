import SwiftUI

struct TeamRosterView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var showingAddPlayer = false
    @State private var editingPlayer: Player? = nil

    private var teamIndex: Int? {
        teamStore.teams.firstIndex(where: { $0.id == teamID })
    }

    private var team: Team? {
        guard let idx = teamIndex else { return nil }
        return teamStore.teams[idx]
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingAddPlayer = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(GoStatsTheme.teal)
                            Text("Add Player")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }

                Section("Players") {
                    if let team, team.players.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No players yet").font(.headline)
                            Text("Tap Add Player to build your roster.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if let team {
                        ForEach(team.players.sorted(by: sortPlayers)) { player in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(player.number) • \(player.name)")
                                        .font(.headline)
                                    Text(primarySecondaryText(for: player))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .onLongPressGesture {
                                editingPlayer = player
                            }
                        }
                        .onDelete(perform: deletePlayers)
                    }
                }
            }
            .navigationTitle(team?.name ?? "Roster")
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView { newPlayer in
                    addPlayer(newPlayer)
                }
            }
            .sheet(item: $editingPlayer) { player in
                EditPlayerSheet(player: player) { updated in
                    updatePlayer(updated)
                }
            }
        }
    }

    private func addPlayer(_ player: Player) {
        guard let idx = teamIndex else { return }
        teamStore.teams[idx].players.append(player)
    }

    private func updatePlayer(_ player: Player) {
        guard let idx = teamIndex else { return }
        if let playerIndex = teamStore.teams[idx].players.firstIndex(where: { $0.id == player.id }) {
            teamStore.teams[idx].players[playerIndex] = player
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        guard let idx = teamIndex else { return }
        teamStore.teams[idx].players.remove(atOffsets: offsets)
    }

    private func sortPlayers(_ a: Player, _ b: Player) -> Bool {
        let order: [Position: Int] = [.gk: 0, .cb: 1, .rb: 2, .lb: 3, .rwb: 4, .lwb: 5, .cdm: 6, .cm: 7, .cam: 8, .rm: 9, .lm: 10, .rw: 11, .lw: 12, .st: 13, .cf: 14]
        let pa = order[a.position] ?? 99
        let pb = order[b.position] ?? 99
        if pa != pb { return pa < pb }
        return a.number < b.number
    }

    private func primarySecondaryText(for player: Player) -> String {
        if let secondary = player.secondaryPosition {
            return "\(player.position.rawValue) • \(secondary.rawValue)"
        }
        return player.position.rawValue
    }
}

private struct EditPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var numberText: String
    @State private var position: Position
    @State private var secondaryPosition: Position?

    let playerID: UUID
    let onSave: (Player) -> Void

    init(player: Player, onSave: @escaping (Player) -> Void) {
        self._name = State(initialValue: player.name)
        self._numberText = State(initialValue: player.jersey.isEmpty ? "\(player.number)" : player.jersey)
        self._position = State(initialValue: player.position)
        self._secondaryPosition = State(initialValue: player.secondaryPosition)
        self.playerID = player.id
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $name)
                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)

                    Picker("Primary Position", selection: $position) {
                        ForEach(Position.rosterPositions) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }

                    Picker("Secondary Position", selection: $secondaryPosition) {
                        Text("None").tag(Position?.none)
                        ForEach(Position.rosterPositions) { pos in
                            Text(pos.rawValue).tag(Optional(pos))
                        }
                    }
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
                        let updated = Player(
                            id: playerID,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            number: number,
                            jersey: jersey,
                            position: position,
                            secondaryPosition: secondaryPosition
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
