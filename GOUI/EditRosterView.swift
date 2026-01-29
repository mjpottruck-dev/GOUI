import SwiftUI

struct EditRosterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var teamName: String
    @State private var fieldSize: Int
    @State private var players: [Player]
    @State private var startingOnFieldIDs: Set<UUID>
    @State private var primaryFormation: Formation
    @State private var primaryGoalkeeperID: UUID?
    @State private var secondaryGoalkeeperID: UUID?
    @State private var thirdGoalkeeperID: UUID?

    let onSave: (Team) -> Void
    let existingTeamID: UUID

    init(team: Team, onSave: @escaping (Team) -> Void) {
        self._teamName = State(initialValue: team.name)
        self._fieldSize = State(initialValue: team.fieldSize)
        self._players = State(initialValue: team.players)
        self._startingOnFieldIDs = State(initialValue: Set(team.startingOnFieldIDs))
        self._primaryFormation = State(initialValue: team.primaryFormation)
        self._primaryGoalkeeperID = State(initialValue: team.primaryGoalkeeperID)
        self._secondaryGoalkeeperID = State(initialValue: team.secondaryGoalkeeperID)
        self._thirdGoalkeeperID = State(initialValue: team.thirdGoalkeeperID)
        self.onSave = onSave
        self.existingTeamID = team.id
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team") {
                    TextField("Team name", text: $teamName)

                    Stepper(value: $fieldSize, in: 5...11) {
                        Text("Field Size: \(fieldSize)")
                    }

                    Picker("Primary Formation", selection: $primaryFormation) {
                        ForEach(Formation.allCases) { formation in
                            Text(formation.rawValue).tag(formation)
                        }
                    }
                }

                Section("Starting On Field") {
                    Text("Tap players to toggle them on/off the field.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    ForEach(players) { p in
                        Button {
                            toggleStarter(p.id)
                        } label: {
                            HStack {
                                Text("#\(p.number) \(p.name)")
                                Spacer()
                                Text(p.position.rawValue)
                                    .foregroundColor(.secondary)

                                if startingOnFieldIDs.contains(p.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Text("Selected: \(startingOnFieldIDs.count) / \(fieldSize)")
                        .font(.footnote)
                        .foregroundColor(starterCountColor)
                }

                Section("Goalkeepers") {
                    if goalkeeperOptions.isEmpty {
                        Text("Add goalkeepers to assign a primary, secondary, and third option.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Primary Goalkeeper", selection: $primaryGoalkeeperID) {
                            Text("None").tag(nil as UUID?)
                            ForEach(goalkeeperOptions) { player in
                                Text(goalkeeperLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        Picker("Secondary Goalkeeper", selection: $secondaryGoalkeeperID) {
                            Text("None").tag(nil as UUID?)
                            ForEach(goalkeeperOptions) { player in
                                Text(goalkeeperLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        Picker("Third Goalkeeper", selection: $thirdGoalkeeperID) {
                            Text("None").tag(nil as UUID?)
                            ForEach(goalkeeperOptions) { player in
                                Text(goalkeeperLabel(for: player)).tag(Optional(player.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Roster")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let clamped = players.filter { startingOnFieldIDs.contains($0.id) }.prefix(fieldSize).map(\.id)
                        let resolvedDepth = Team.goalkeeperDepthIDs(
                            from: players,
                            currentPrimary: primaryGoalkeeperID,
                            currentSecondary: secondaryGoalkeeperID,
                            currentThird: thirdGoalkeeperID
                        )
                        let team = Team(
                            id: existingTeamID,
                            name: teamName.trimmingCharacters(in: .whitespacesAndNewlines),
                            players: players,
                            fieldSize: fieldSize,
                            startingOnFieldIDs: clamped,
                            primaryFormation: primaryFormation,
                            primaryGoalkeeperID: resolvedDepth.primary,
                            secondaryGoalkeeperID: resolvedDepth.secondary,
                            thirdGoalkeeperID: resolvedDepth.third,
                            matches: []
                        )
                        onSave(team)
                        dismiss()
                    }
                    .disabled(teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var starterCountColor: Color {
        startingOnFieldIDs.count == fieldSize ? .secondary : .red
    }

    private func toggleStarter(_ id: UUID) {
        if startingOnFieldIDs.contains(id) {
            startingOnFieldIDs.remove(id)
        } else {
            if startingOnFieldIDs.count < fieldSize {
                startingOnFieldIDs.insert(id)
            }
        }
    }

    private var goalkeeperOptions: [Player] {
        players.filter { $0.position == .gk }.sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.number < rhs.number
        }
    }

    private func goalkeeperLabel(for player: Player) -> String {
        "#\(player.number) \(player.name)"
    }
}
