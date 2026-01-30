import SwiftUI

struct DualMatchEntryView: View {
    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var segmentName: String = ""
    @State private var summary: String = ""

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Summary") {
                    TextField("Set/Bout", text: $segmentName)
                    TextField("Result", text: $summary)
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(segmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Entries") {
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
            .navigationTitle(team?.name ?? "Dual Match")
        }
    }

    private func saveEntry() {
        let entry = ResultEntry(
            gameID: store.currentMatchID,
            playerID: UUID(),
            segmentName: segmentName,
            valueString: summary,
            valueDouble: nil,
            unit: nil
        )
        store.resultEntries.append(entry)
        segmentName = ""
        summary = ""
    }
}
