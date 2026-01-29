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
    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var exportError: String? = nil

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
                    if store.sport.id == SportCatalog.defaultSportID {
                        Button("Export → MaxPreps (.txt)") {
                            exportMaxPreps()
                        }
                    }

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
        .sheet(item: $shareSheetPayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .alert("Export Failed", isPresented: Binding(get: { exportError != nil }, set: { _ in exportError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
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

    private func exportMaxPreps() {
        let record = store.buildMatchRecord(
            opponent: opponent,
            title: title,
            notes: notes
        )
        let matchName = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? opponent
            : title
        let safeName = MaxPrepsExport.sanitizedFilename(matchName.isEmpty ? "Match" : matchName)

        let teamRows = MaxPrepsExport.teamRows(
            players: store.players,
            stats: record.playerStats,
            seconds: record.playerSeconds
        )
        let teamText = MaxPrepsExport.text(fields: MaxPrepsExport.teamFields, rows: teamRows)

        do {
            var urls: [URL] = []
            let teamURL = try MaxPrepsExport.writeTempTXT(
                filename: "MaxPreps_\(safeName)_Team",
                contents: teamText
            )
            urls.append(teamURL)

            let keeperRows = MaxPrepsExport.keeperRows(
                players: store.players,
                stats: record.playerStats,
                seconds: record.playerSeconds
            )
            if !keeperRows.isEmpty {
                let keeperText = MaxPrepsExport.text(fields: MaxPrepsExport.keeperFields, rows: keeperRows)
                let keeperURL = try MaxPrepsExport.writeTempTXT(
                    filename: "MaxPreps_\(safeName)_Keeper",
                    contents: keeperText
                )
                urls.append(keeperURL)
            }

            shareSheetPayload = ShareSheetPayload(items: urls)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [URL]
    }
}
