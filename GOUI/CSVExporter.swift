import Foundation

enum CSVExporter {

    // MARK: - Public API

    /// Builds a CSV string for a single match (team roster + per-match stats snapshot).
    static func matchCSV(team: Team, match: MatchRecord, sport: (any SportDefinition)? = nil) -> String {
        var lines: [String] = []
        let resolvedSport = sport ?? SportCatalog.sport(for: match.sportID)
        let statColumns = resolvedSport.statSchema.filter { $0.countsForPlayer }

        // Header row
        lines.append((
            [
            "Team",
            "MatchDate",
            "Title",
            "Opponent",
            "GoalsFor",
            "GoalsAgainst",
            "SecondsElapsed",
            "FieldSize",
            "PlayerNumber",
            "PlayerName",
            "Position",
            "MinutesPlayed"
            ]
            + statColumns.map(\.id)
        ).joined(separator: ","))

        let dateString = match.date.formatted(date: .numeric, time: .shortened)

        for p in team.players {
            let secs = match.playerSeconds[p.id] ?? 0
            let mins = secs / 60

            let st = match.playerStats[p.id] ?? PlayerStatLine()

            let positionLabel = p.displayPosition(for: resolvedSport) ?? ""
            let row: [String] = [
                esc(team.name),
                esc(dateString),
                esc(match.title),
                esc(match.opponent),
                "\(match.goalsFor)",
                "\(match.goalsAgainst)",
                "\(match.secondsElapsed)",
                "\(match.fieldSize)",
                "\(p.number)",
                esc(p.name),
                esc(positionLabel),
                "\(mins)"
            ] + statColumns.map { stat in
                "\(st.value(for: stat.id))"
            }

            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Writes CSV contents to a temporary file and returns its URL.
    static func writeTempCSV(filename: String, contents: String) throws -> URL {
        let safeName = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).csv")

        try contents.data(using: .utf8)?.write(to: url, options: [.atomic])
        return url
    }

    // MARK: - Helpers

    /// Escape CSV values (quotes, commas, newlines).
    private static func esc(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            let doubled = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return s
    }
}
