import SwiftUI

struct EndMatchSheet: View {

    @ObservedObject var store: MatchStore

    let teamStore: TeamStore
    let teamID: UUID

    let team: Team
    let formation: Formation

    @Environment(\.dismiss) private var dismiss

    @State private var opponent: String = ""
    @State private var title: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Summary") {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text("\(store.goalsFor)–\(store.goalsAgainst)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(store.timeString)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Match Info") {
                    TextField("Opponent", text: $opponent)
                    TextField("Title (optional)", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Button("Save Match") { saveMatch() }
                        .disabled(opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Discard Match", role: .destructive) {
                        discardMatch()
                    }
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
        let record = store.buildMatchRecord(
            opponent: opponent,
            title: title,
            notes: notes
        )

        teamStore.addMatchRecord(teamID: teamID, record: record)

        store.resetForNewMatch(team: team, formation: formation, seasonID: teamStore.activeSeasonID)

        dismiss()
    }

    private func discardMatch() {
        store.resetForNewMatch(team: team, formation: formation, seasonID: teamStore.activeSeasonID)
        dismiss()
    }
}
