import SwiftUI

struct EditRosterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var teamName: String
    @State private var fieldSize: Int
    @State private var players: [Player]
    @State private var startingOnFieldIDs: Set<UUID>
    @State private var primaryFormation: Formation

    let onSave: (Team) -> Void
    let existingTeamID: UUID

    init(team: Team, onSave: @escaping (Team) -> Void) {
        self._teamName = State(initialValue: team.name)
        self._fieldSize = State(initialValue: team.fieldSize)
        self._players = State(initialValue: team.players)
        self._startingOnFieldIDs = State(initialValue: Set(team.startingOnFieldIDs))
        self._primaryFormation = State(initialValue: team.primaryFormation)
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
            }
            .navigationTitle("Edit Roster")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let clamped = Array(startingOnFieldIDs).prefix(fieldSize)
                        let team = Team(
                            id: existingTeamID,
                            name: teamName.trimmingCharacters(in: .whitespacesAndNewlines),
                            players: players,
                            fieldSize: fieldSize,
                            startingOnFieldIDs: Array(clamped),
                            primaryFormation: primaryFormation,
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
}
