import SwiftUI

struct MeetEntryView: View {
    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var selectedPlayerID: UUID?
    @State private var eventName: String = ""
    @State private var value: String = ""
    @State private var unit: String = ""

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Event", text: $eventName)
                    Picker("Athlete", selection: $selectedPlayerID) {
                        ForEach(team?.players ?? []) { player in
                            Text(player.name).tag(Optional(player.id))
                        }
                    }
                    TextField("Result", text: $value)
                    TextField("Unit (optional)", text: $unit)

                    Button("Save Result") {
                        saveEntry()
                    }
                    .disabled(eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPlayerID == nil)
                }

                Section("Leaderboard") {
                    ForEach(store.resultEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.segmentName)
                                .font(.headline)
                            Text(entry.valueString ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Meet Entry")
        }
    }

    private func saveEntry() {
        guard let playerID = selectedPlayerID else { return }
        let entry = ResultEntry(
            gameID: store.currentMatchID,
            playerID: playerID,
            segmentName: eventName,
            valueString: value,
            valueDouble: Double(value),
            unit: unit
        )
        store.resultEntries.append(entry)
        eventName = ""
        value = ""
        unit = ""
    }
}
