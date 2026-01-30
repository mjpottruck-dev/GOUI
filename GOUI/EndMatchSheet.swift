import SwiftUI

struct EndMatchSheet: View {

    @ObservedObject var store: MatchStore

    let teamStore: TeamStore
    let teamID: UUID

    let team: Team
    let formation: Formation

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var permissionService: PermissionService
    @EnvironmentObject var analytics: AnalyticsService

    @State private var opponent: String = ""
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var location: String = ""
    @State private var matchDate: Date = Date()
    @State private var meetEventsText: String = ""
    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var exportError: String? = nil
    @State private var showPricing = false
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Summary") {
                    if store.sport.supportsTeamScore {
                        HStack {
                            Text("Score")
                            Spacer()
                            Text("\(store.goalsFor)–\(store.goalsAgainst)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Scoring")
                            Spacer()
                            Text("Individual")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if store.sport.supportsTimer {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(store.timeString)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(infoSectionTitle) {
                    DatePicker("Date & Time", selection: $matchDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Opponent", text: $opponent)
                    TextField("Location (optional)", text: $location)
                    TextField("Title (optional)", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if isMeetSport {
                    Section("Meet Events (optional)") {
                        TextField("One event per line", text: $meetEventsText, axis: .vertical)
                            .lineLimit(3...8)
                    }

                    if !meetStatIDs.isEmpty {
                        Section("Results") {
                            ForEach($store.players) { $player in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("#\(player.number) \(player.name)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 12) {
                                        if meetStatIDs.contains("timeSeconds") {
                                            statField(player: $player, statID: "timeSeconds", label: "Time (sec)")
                                        }
                                        if meetStatIDs.contains("distanceMeters") {
                                            statField(player: $player, statID: "distanceMeters", label: "Distance (m)")
                                        }
                                        if meetStatIDs.contains("place") {
                                            statField(player: $player, statID: "place", label: "Place")
                                        }
                                    }

                                    if meetStatIDs.contains("personalRecord") {
                                        Toggle("PR", isOn: prBinding(for: $player))
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }

                Section {
                    if store.sport.id == SportCatalog.defaultSportID {
                        Button("Export → MaxPreps (.txt)") {
                            exportMaxPreps()
                        }
                    }

                    Button(isMeetSport ? "Save Meet" : "Save Match") { saveMatch() }

                    Button("Discard Match", role: .destructive) {
                        discardMatch()
                    }
                }
            }
            .navigationTitle(isMeetSport ? "End Meet" : "End Match")
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
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coach access is required to export.")
        }
        .sheet(isPresented: $showPricing) {
            PricingView()
                .environmentObject(subscriptionManager)
        }
    }

    private func saveMatch() {
        let record = store.buildMatchRecord(
            opponent: opponent,
            title: title,
            notes: notes,
            date: matchDate,
            location: location,
            meetEvents: parsedMeetEvents(),
            seasonName: teamStore.activeSeason(for: teamID)?.name ?? ""
        )

        teamStore.addMatchRecord(teamID: teamID, record: record)

        store.resetForNewMatch(
            team: team,
            formation: formation,
            seasonID: teamStore.activeSeasonID(for: teamID),
            template: store.activeTemplate
        )

        dismiss()
    }

    private func discardMatch() {
        store.resetForNewMatch(
            team: team,
            formation: formation,
            seasonID: teamStore.activeSeasonID(for: teamID),
            template: store.activeTemplate
        )
        dismiss()
    }

    private func exportMaxPreps() {
        guard canExport() else { return }
        let record = store.buildMatchRecord(
            opponent: opponent,
            title: title,
            notes: notes,
            date: matchDate,
            location: location,
            meetEvents: parsedMeetEvents(),
            seasonName: teamStore.activeSeason(for: teamID)?.name ?? ""
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
            subscriptionManager.recordExport()
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func canExport() -> Bool {
        analytics.log(.tappedExport, metadata: ["source": "end_match"])
        guard permissionService.canExport(teamID: teamID) else {
            showPermissionAlert = true
            return false
        }
        if subscriptionManager.canExport() {
            return true
        }
        showPricing = true
        return false
    }

    private var isMeetSport: Bool {
        switch store.sport.id {
        case SportCatalog.swimmingID,
             SportCatalog.trackID,
             SportCatalog.crossCountryID,
             SportCatalog.golfID:
            return true
        default:
            return false
        }
    }

    private var infoSectionTitle: String {
        isMeetSport ? "Meet Info" : "Match Info"
    }

    private var meetStatIDs: [String] {
        switch store.sport.id {
        case SportCatalog.swimmingID:
            return ["timeSeconds", "place", "personalRecord"]
        case SportCatalog.trackID:
            return ["timeSeconds", "distanceMeters", "place", "personalRecord"]
        case SportCatalog.crossCountryID:
            return ["timeSeconds", "place", "personalRecord"]
        default:
            return []
        }
    }

    private func statField(player: Binding<Player>, statID: String, label: String) -> some View {
        let binding = Binding<String>(
            get: {
                let value = player.wrappedValue.statValue(for: statID)
                return value == 0 ? "" : "\(value)"
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let value = Int(trimmed) ?? 0
                player.wrappedValue.setStatValue(value, for: statID)
            }
        )

        return TextField(label, text: binding)
            .keyboardType(.numberPad)
    }

    private func prBinding(for player: Binding<Player>) -> Binding<Bool> {
        Binding<Bool>(
            get: { player.wrappedValue.statValue(for: "personalRecord") > 0 },
            set: { newValue in
                player.wrappedValue.setStatValue(newValue ? 1 : 0, for: "personalRecord")
            }
        )
    }

    private func parsedMeetEvents() -> [String] {
        meetEventsText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [URL]
    }
}
