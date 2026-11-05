import SwiftUI

/// Edit a saved match after the game: fix the opponent, date, score, or any
/// player's minutes and stats (e.g. a missed sub or the wrong scorer), or delete it.
/// Season and player stats are computed from saved matches, so they update on save.
struct EditMatchSheet: View {
    let teamStore: TeamStore
    let teamID: UUID
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draft: MatchRecord
    @State private var minutesByPlayer: [UUID: Int]
    @State private var showDeleteConfirm = false
    @State private var showAddPlayer = false

    init(teamStore: TeamStore, teamID: UUID, match: MatchRecord, onDelete: @escaping () -> Void) {
        self.teamStore = teamStore
        self.teamID = teamID
        self.onDelete = onDelete
        _draft = State(initialValue: match)
        _minutesByPlayer = State(initialValue: match.playerSeconds.mapValues { ($0 + 30) / 60 })
    }

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    /// Players with any minutes or stats in this match, in jersey order.
    private var matchPlayers: [Player] {
        let ids = Set(draft.playerSeconds.keys).union(draft.playerStats.keys)
        return (team?.players ?? [])
            .filter { ids.contains($0.id) }
            .sorted { ($0.number, $0.name) < ($1.number, $1.name) }
    }

    private var playersNotInMatch: [Player] {
        let ids = Set(draft.playerSeconds.keys).union(draft.playerStats.keys)
        return (team?.players ?? [])
            .filter { !ids.contains($0.id) }
            .sorted { ($0.number, $0.name) < ($1.number, $1.name) }
    }

    private var playerGoalsTotal: Int {
        draft.playerStats.values.reduce(0) { $0 + $1.goals }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Match") {
                    TextField("Opponent", text: $draft.opponent)
                    DatePicker("Date", selection: $draft.date)
                    TextField("Venue", text: $draft.venue)
                    TextField("Title", text: $draft.title)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section {
                    Stepper("Our goals: \(draft.goalsFor)", value: $draft.goalsFor, in: 0...99)
                    Stepper("Their goals: \(draft.goalsAgainst)", value: $draft.goalsAgainst, in: 0...99)
                } header: {
                    Text("Score")
                } footer: {
                    if playerGoalsTotal != draft.goalsFor {
                        Text("Player goals add up to \(playerGoalsTotal), but the score says \(draft.goalsFor). Own goals by the other team can explain a difference.")
                    }
                }

                Section {
                    if matchPlayers.isEmpty {
                        Text("No players recorded in this match.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(matchPlayers) { player in
                        DisclosureGroup {
                            playerEditor(player)
                        } label: {
                            playerSummary(player)
                        }
                    }
                    if !playersNotInMatch.isEmpty {
                        Button("Add a player who played") { showAddPlayer = true }
                    }
                } header: {
                    Text("Players")
                } footer: {
                    Text("Tap a player to fix minutes or stats, e.g. a missed sub.")
                }

                Section {
                    Button("Delete Match", role: .destructive) { showDeleteConfirm = true }
                }
            }
            .navigationTitle("Edit Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete this match?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Match", role: .destructive) {
                    teamStore.deleteMatch(teamID: teamID, matchID: draft.id)
                    dismiss()
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Its stats will be removed from the season totals. This can't be undone.")
            }
            .confirmationDialog("Add player", isPresented: $showAddPlayer, titleVisibility: .visible) {
                ForEach(playersNotInMatch) { player in
                    Button("#\(player.number) \(player.name)") {
                        draft.playerStats[player.id] = PlayerStatLine()
                        minutesByPlayer[player.id] = 0
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Player rows

    private func playerSummary(_ player: Player) -> some View {
        let line = draft.playerStats[player.id] ?? PlayerStatLine()
        let minutes = minutesByPlayer[player.id] ?? 0
        var parts = ["\(minutes) min"]
        if line.goals > 0 { parts.append("\(line.goals)G") }
        if line.assists > 0 { parts.append("\(line.assists)A") }
        if line.saves > 0 { parts.append("\(line.saves) saves") }
        return HStack {
            Text("#\(player.number) \(player.name)")
            Spacer()
            Text(parts.joined(separator: " · "))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func playerEditor(_ player: Player) -> some View {
        Stepper("Minutes: \(minutesByPlayer[player.id] ?? 0)",
                value: minutesBinding(player.id), in: 0...150)
        statStepper("Goals", \.goals, player.id)
        statStepper("Assists", \.assists, player.id)
        statStepper("Shots", \.shots, player.id)
        statStepper("Shots on target", \.shotsOnTarget, player.id)
        statStepper("Yellow cards", \.yellowCards, player.id, max: 2)
        statStepper("Red cards", \.redCards, player.id, max: 1)
        if player.position == .gk || (draft.playerStats[player.id]?.saves ?? 0) > 0 {
            statStepper("Saves", \.saves, player.id)
            statStepper("Goals conceded", \.goalsConceded, player.id)
        }
    }

    private func statStepper(_ title: String,
                             _ keyPath: WritableKeyPath<PlayerStatLine, Int>,
                             _ playerID: UUID,
                             max: Int = 99) -> some View {
        let binding = Binding<Int>(
            get: { draft.playerStats[playerID]?[keyPath: keyPath] ?? 0 },
            set: { newValue in
                var line = draft.playerStats[playerID] ?? PlayerStatLine()
                line[keyPath: keyPath] = newValue
                draft.playerStats[playerID] = line
            }
        )
        return Stepper("\(title): \(binding.wrappedValue)", value: binding, in: 0...max)
    }

    private func minutesBinding(_ playerID: UUID) -> Binding<Int> {
        Binding(
            get: { minutesByPlayer[playerID] ?? 0 },
            set: { minutesByPlayer[playerID] = $0 }
        )
    }

    // MARK: - Save

    private func save() {
        var updated = draft
        // Only overwrite seconds for players whose minutes were actually changed, so
        // untouched players keep their exact recorded time.
        let originalMinutes = draft.playerSeconds.mapValues { ($0 + 30) / 60 }
        for (id, minutes) in minutesByPlayer where originalMinutes[id] != minutes {
            updated.playerSeconds[id] = minutes * 60
        }
        // Keep shots on target consistent with shots.
        for (id, var line) in updated.playerStats {
            line.shots = max(line.shots, line.shotsOnTarget)
            updated.playerStats[id] = line
        }
        teamStore.updateMatch(teamID: teamID, match: updated)
        // The AI recap described the old numbers.
        UserDefaults.standard.removeObject(forKey: "match_insight_\(updated.id.uuidString)")
        dismiss()
    }
}
