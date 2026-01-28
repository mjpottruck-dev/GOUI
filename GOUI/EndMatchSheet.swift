import SwiftUI

struct EndMatchSheet: View {

    @ObservedObject var store: MatchStore

    let teamStore: TeamStore
    let teamID: UUID

    // Your resetForNewMatch requires these
    let team: Team
    let formation: Formation

    @Environment(\.dismiss) private var dismiss

    @State private var opponent: String = ""
    @State private var title: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Match Info") {
                    TextField("Opponent", text: $opponent)
                    TextField("Title (optional)", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Button("Save Match") { saveMatch() }
                        .disabled(opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("End Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveMatch() {
        let record = MatchRecord(
            id: UUID(),
            date: Date(),
            opponent: opponent,
            title: title,
            notes: notes,
            goalsFor: store.goalsFor,
            goalsAgainst: store.goalsAgainst,
            secondsElapsed: store.secondsElapsed,
            fieldSize: store.fieldSize,

            // ✅ IMPORTANT: your MatchStore doesn’t expose these
            // so we save empty dictionaries to compile.
            playerSeconds: [:],                // [UUID : Int]
            playerStats: [:]                   // [UUID : PlayerStatLine]
        )

        teamStore.addMatchRecord(teamID: teamID, record: record)

        store.resetForNewMatch(team: team, formation: formation)

        dismiss()
    }
}

