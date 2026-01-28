import SwiftUI

struct CreateTeamView: View {

    var teamStore: TeamStore
    var onCreated: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var fieldSize: Int = 11

    var body: some View {
        NavigationStack {
            Form {
                Section("TEAM") {
                    TextField("Team name", text: $name)
                    Picker("Field size", selection: $fieldSize) {
                        Text("7v7").tag(7)
                        Text("9v9").tag(9)
                        Text("11v11").tag(11)
                    }
                }

                Section {
                    Button {
                        create()
                    } label: {
                        Text("Create Team")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Create Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let team = Team(
            id: UUID(),
            name: trimmed,
            players: [],
            fieldSize: fieldSize,
            startingOnFieldIDs: [],
            matches: []
        )

        teamStore.addTeam(team)
        onCreated(team.id)
        dismiss()
    }
}

