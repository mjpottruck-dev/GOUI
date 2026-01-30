import Foundation

enum CSVExporter {

    // MARK: - Public API

    /// Builds a CSV string for a single match (team roster + per-match stats snapshot).
    static func matchCSV(team: Team, match: MatchRecord, sport: (any SportDefinition)? = nil) -> String {
        var lines: [String] = []
        let resolvedSport = sport ?? SportCatalog.sport(for: match.sportID)
        let statColumns = resolvedSport.statSchema.filter { $0.countsForPlayer }
        let periodColumns = periodScoreColumns(for: resolvedSport, match: match)
        let holeColumns = holeScoreColumns(for: resolvedSport, match: match)

        // Header row
        lines.append((
            [
            "Team",
            "Season",
            "MatchDate",
            "Title",
            "Opponent",
            "Location",
            "Sport",
            "Template",
            "MeetEvents",
            "GoalsFor",
            "GoalsAgainst",
            "SecondsElapsed",
            "FieldSize",
            "PlayerNumber",
            "PlayerName",
            "Position",
            "MinutesPlayed"
            ]
            + periodColumns
            + holeColumns
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
                esc(match.seasonName),
                esc(dateString),
                esc(match.title),
                esc(match.opponent),
                esc(match.location),
                esc(resolvedSport.displayName),
                esc(match.templateName ?? ""),
                esc(match.meetEvents.joined(separator: " | ")),
                "\(match.goalsFor)",
                "\(match.goalsAgainst)",
                "\(match.secondsElapsed)",
                "\(match.fieldSize)",
                "\(p.number)",
                esc(p.name),
                esc(positionLabel),
                "\(mins)"
            ] + periodScoresRow(for: match, sport: resolvedSport) + holeScoresRow(for: match, sport: resolvedSport, player: p) + statColumns.map { stat in
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

    private static func periodScoreColumns(for sport: any SportDefinition, match: MatchRecord) -> [String] {
        guard sport.supportsPeriods else { return [] }
        let count = match.periodScores.isEmpty ? sport.periods.count : match.periodScores.count
        let prefix = sport.id == SportCatalog.volleyballID || sport.id == SportCatalog.tennisID ? "Set" : "Period"
        return (1...max(count, 0)).flatMap { index in
            ["\(prefix)\(index)For", "\(prefix)\(index)Against"]
        }
    }

    private static func periodScoresRow(for match: MatchRecord, sport: any SportDefinition) -> [String] {
        guard sport.supportsPeriods else { return [] }
        let scores = match.periodScores
        let count = max(scores.count, sport.periods.count)
        return (0..<count).flatMap { index in
            if scores.indices.contains(index) {
                return ["\(scores[index].teamScore)", "\(scores[index].opponentScore)"]
            }
            return ["0", "0"]
        }
    }

    private static func holeScoreColumns(for sport: any SportDefinition, match: MatchRecord) -> [String] {
        guard sport.supportsHoles else { return [] }
        let count = holeCount(for: match, sport: sport)
        let holes = (1...count).map { "Hole\($0)" }
        return holes + ["TotalStrokes", "TotalPutts"]
    }

    private static func holeScoresRow(for match: MatchRecord, sport: any SportDefinition, player: Player) -> [String] {
        guard sport.supportsHoles else { return [] }
        let count = holeCount(for: match, sport: sport)
        let scores = match.playerHoleScores[player.id] ?? Array(repeating: 0, count: count)
        let putts = match.playerHolePutts[player.id] ?? Array(repeating: 0, count: count)
        let paddedScores = Array(scores.prefix(count)) + Array(repeating: 0, count: max(0, count - scores.count))
        let paddedPutts = Array(putts.prefix(count)) + Array(repeating: 0, count: max(0, count - putts.count))
        let totalStrokes = paddedScores.reduce(0, +)
        let totalPutts = paddedPutts.reduce(0, +)
        return paddedScores.map { "\($0)" } + ["\(totalStrokes)", "\(totalPutts)"]
    }

    private static func holeCount(for match: MatchRecord, sport: any SportDefinition) -> Int {
        if let count = match.playerHoleScores.values.first?.count {
            return count
        }
        if sport.supportsHoles {
            return sport.defaultHoleCount
        }
        return 0
    }
}
