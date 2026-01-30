import SwiftUI

struct ExportCenterView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @EnvironmentObject var permissionService: PermissionService
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedMatchID: UUID?
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showShare = false

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var matches: [MatchRecord] {
        team?.matches ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Match") {
                    Picker("Match", selection: $selectedMatchID) {
                        Text("Latest").tag(Optional(matches.first?.id))
                        ForEach(matches) { match in
                            Text(match.title.isEmpty ? match.date.formatted(date: .abbreviated, time: .omitted) : match.title)
                                .tag(Optional(match.id))
                        }
                    }
                }

                Section("Export") {
                    Button("Export CSV") {
                        exportCSV()
                    }
                    .disabled(!canExport)

                    Button("Export MaxPreps Stub") {
                        exportMaxPreps()
                    }
                    .disabled(!canExport)

                    if let exportError {
                        Text(exportError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export Center")
            .sheet(isPresented: $showShare) {
                if let exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
        }
    }

    private var canExport: Bool {
        guard let team else { return false }
        return permissionService.canExport(teamID: team.id) && subscriptionManager.canExport()
    }

    private func exportCSV() {
        guard let team, let match = resolveMatch() else { return }
        let sport = SportCatalog.sport(for: match.sportID)
        let csv = CSVExporter.matchCSV(team: team, match: match, sport: sport)
        let safeName = MaxPrepsExport.sanitizedFilename(match.title.isEmpty ? "Match" : match.title)
        do {
            exportURL = try CSVExporter.writeTempCSV(filename: "GoStats_\(safeName)", contents: csv)
            subscriptionManager.recordExport()
            showShare = true
        } catch {
            exportError = "Export failed."
        }
    }

    private func exportMaxPreps() {
        guard let team, let match = resolveMatch() else { return }
        let sport = SportCatalog.sport(for: match.sportID)
        let adapter = MaxPrepsAdapterFactory.adapter(for: sport)
        let text = adapter.export(game: match, team: team, sport: sport)
        let safeName = MaxPrepsExport.sanitizedFilename(match.title.isEmpty ? "Match" : match.title)
        do {
            exportURL = try MaxPrepsExport.writeTempTXT(filename: "MaxPreps_\(safeName)", contents: text)
            subscriptionManager.recordExport()
            showShare = true
        } catch {
            exportError = "Export failed."
        }
    }

    private func resolveMatch() -> MatchRecord? {
        guard let team else { return nil }
        if let selectedMatchID {
            return team.matches.first(where: { $0.id == selectedMatchID }) ?? team.matches.first
        }
        return team.matches.first
    }
}
