import SwiftUI

struct MatchDetailView: View {
    let match: MatchRecord
    let team: Team
    let sport: any SportDefinition
    @State private var selectedPlayerDetail: PlayerDetail? = nil
    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var exportError: String? = nil

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    LiquidGlassContainer(material: .thinMaterial) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(primaryMatchLabel)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)

                                    Text(match.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }

                                Spacer()

                                if sport.supportsTeamScore {
                                    Text("\(match.goalsFor)–\(match.goalsAgainst)")
                                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(GoStatsTheme.text)
                                } else {
                                    Text("Individual")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }

                            HStack(spacing: 10) {
                                if sport.supportsTimer {
                                    chip("Time", secondsToTime(match.secondsElapsed))
                                }
                                if sport.supportsTeamScore {
                                    chip("Field", "\(match.fieldSize)v\(match.fieldSize)")
                                }
                                chip("Sport", sport.displayName)
                                if !match.seasonName.isEmpty {
                                    chip("Season", match.seasonName)
                                }
                                if let templateName = match.templateName, !templateName.isEmpty {
                                    chip("Template", templateName)
                                }
                                if !match.location.isEmpty {
                                    chip("Location", match.location)
                                }
                            }

                            if !match.title.isEmpty || !match.notes.isEmpty {
                                Divider().opacity(0.55)
                                if !match.title.isEmpty {
                                    Text(match.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                }
                                if !match.notes.isEmpty {
                                    Text(match.notes)
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }
                            if !match.meetEvents.isEmpty {
                                Divider().opacity(0.55)
                                Text("Events")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text2)
                                ForEach(match.meetEvents, id: \.self) { event in
                                    Text(event)
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.text)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PLAYER STATS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.primary)

                            VStack(spacing: 10) {
                                ForEach(sortedPlayersForMatch, id: \.id) { p in
                                    playerRow(
                                        player: p,
                                        line: match.playerStats[p.id] ?? PlayerStatLine(),
                                        seconds: match.playerSeconds[p.id] ?? 0
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        LiquidGlassContainer(cornerRadius: 22) {
                            Button(action: exportCSV) {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export → CSV")
                                        .font(.system(size: 15, weight: .semibold))
                                    Spacer()
                                }
                                .foregroundStyle(GoStatsTheme.text)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        if sport.id == SportCatalog.wrestlingID {
                            LiquidGlassContainer(cornerRadius: 22) {
                                Button(action: exportWrestlingSummary) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "doc.text")
                                        Text("Export → Bout Summary (.txt)")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .foregroundStyle(GoStatsTheme.text)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                        }

                        if sport.id == SportCatalog.defaultSportID {
                            LiquidGlassContainer(cornerRadius: 22) {
                                Button(action: exportMaxPreps) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Export → MaxPreps (.txt)")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .foregroundStyle(GoStatsTheme.text)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPlayerDetail) { detail in
            NavigationStack {
                ZStack {
                    GoStatsTheme.bg.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 12) {
                            LiquidGlassContainer(cornerRadius: 22) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PLAYER")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.primary)

                                    Text("#\(detail.player.number) \(detail.player.name)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)

                                    let positionLabel = detail.player.displayPosition(for: sport) ?? "No Position"
                                    Text("\(positionLabel) • \(secondsToTime(detail.seconds))")
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }

                            LiquidGlassContainer(cornerRadius: 22) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("MATCH STATS")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.primary)

                                    VStack(spacing: 8) {
                                        ForEach(statTypesForDetail, id: \.id) { stat in
                                            statsRow(stat.displayName, detail.line.value(for: stat.id))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Player Stats")
                .navigationBarTitleDisplayMode(.inline)
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

    private var sortedPlayersForMatch: [Player] {
        let appearedIDs = Set(match.playerSeconds.keys)
        let appeared = team.players.filter { appearedIDs.contains($0.id) }
        return appeared.sorted { ($0.number, $0.name) < ($1.number, $1.name) }
    }

    private var primaryMatchLabel: String {
        if !match.opponent.isEmpty {
            return match.opponent
        }
        if !match.title.isEmpty {
            return match.title
        }
        return "Meet"
    }

    private func playerRow(player: Player, line: PlayerStatLine, seconds: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("#\(player.number) \(player.name)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                let positionLabel = player.displayPosition(for: sport) ?? "No Position"
                Text("\(positionLabel) • \(secondsToTime(seconds))")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }

            Spacer()

            HStack(spacing: 10) {
                ForEach(statTypesForRow, id: \.id) { stat in
                    statPill(stat.shortLabel ?? stat.displayName, "\(line.value(for: stat.id))")
                }
                statsActionButton {
                    selectedPlayerDetail = PlayerDetail(player: player, line: line, seconds: seconds)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.50))
        )
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private func statsActionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.primary)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View all stats")
    }

    private func chip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func secondsToTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }

    private func statsRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
            Spacer()
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text2)
        }
    }

    private var statTypesForRow: [StatType] {
        Array(sport.statSchema.filter { $0.countsForPlayer }.prefix(4))
    }

    private var statTypesForDetail: [StatType] {
        sport.statSchema.filter { $0.countsForPlayer }
    }

    private func exportCSV() {
        let csv = CSVExporter.matchCSV(team: team, match: match, sport: sport)
        let matchName = match.title.isEmpty ? match.opponent : match.title
        let safeName = MaxPrepsExport.sanitizedFilename(matchName.isEmpty ? "Match" : matchName)

        do {
            let url = try CSVExporter.writeTempCSV(
                filename: "GoStats_\(safeName)",
                contents: csv
            )
            shareSheetPayload = ShareSheetPayload(items: [url])
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportMaxPreps() {
        let roster = team.players.filter { match.playerSeconds.keys.contains($0.id) }
        let matchName = match.title.isEmpty ? match.opponent : match.title
        let safeName = MaxPrepsExport.sanitizedFilename(matchName.isEmpty ? "Match" : matchName)

        let teamRows = MaxPrepsExport.teamRows(
            players: roster,
            stats: match.playerStats,
            seconds: match.playerSeconds
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
                players: roster,
                stats: match.playerStats,
                seconds: match.playerSeconds
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

    private func exportWrestlingSummary() {
        let matchName = match.title.isEmpty ? match.opponent : match.title
        let safeName = MaxPrepsExport.sanitizedFilename(matchName.isEmpty ? "Bout" : matchName)
        let roster = team.players.filter { match.playerStats.keys.contains($0.id) }

        var lines: [String] = [
            "Bout Summary",
            "Team: \(team.name)",
            "Opponent: \(match.opponent.isEmpty ? "N/A" : match.opponent)",
            "Date: \(match.date.formatted(date: .abbreviated, time: .shortened))",
            "Season: \(match.seasonName.isEmpty ? "N/A" : match.seasonName)",
            ""
        ]

        for player in roster {
            let line = match.playerStats[player.id] ?? PlayerStatLine()
            lines.append("#\(player.number) \(player.name)")
            lines.append("Points: \(line.value(for: "matchPoints")) | TD: \(line.value(for: "takedown")) | ESC: \(line.value(for: "escape")) | REV: \(line.value(for: "reversal")) | NF: \(line.value(for: "nearFall")) | PEN: \(line.value(for: "penalty")) | PIN: \(line.value(for: "pins"))")
            lines.append("")
        }

        let summary = lines.joined(separator: "\n")

        do {
            let url = try MaxPrepsExport.writeTempTXT(filename: "Bout_\(safeName)", contents: summary)
            shareSheetPayload = ShareSheetPayload(items: [url])
        } catch {
            exportError = error.localizedDescription
        }
    }

    private struct PlayerDetail: Identifiable {
        let id: UUID
        let player: Player
        let line: PlayerStatLine
        let seconds: Int

        init(player: Player, line: PlayerStatLine, seconds: Int) {
            self.id = player.id
            self.player = player
            self.line = line
            self.seconds = seconds
        }
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [URL]
    }
}
