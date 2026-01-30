import Foundation

protocol MaxPrepsExportAdapter {
    func export(game: MatchRecord, team: Team, sport: any SportDefinition) -> String
    func fieldMapping(for sport: any SportDefinition) -> [String: String]
}

struct GenericMaxPrepsAdapter: MaxPrepsExportAdapter {
    func export(game: MatchRecord, team: Team, sport: any SportDefinition) -> String {
        let statColumns = sport.statSchema.filter { $0.countsForPlayer }
        var lines: [String] = []
        let header = [
            "Team",
            "Sport",
            "MatchDate",
            "Opponent",
            "Player",
            "PlayerNumber"
        ] + statColumns.map(
            { $0.id }
        )
        lines.append(header.joined(separator: ","))

        let dateString = game.date.formatted(date: .numeric, time: .shortened)
        for player in team.players {
            let stats = game.playerStats[player.id] ?? PlayerStatLine()
            let row = [
                csv(team.name),
                csv(sport.displayName),
                csv(dateString),
                csv(game.opponent),
                csv(player.name),
                "\(player.number)"
            ] + statColumns.map { "\(stats.value(for: $0.id))" }
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    func fieldMapping(for sport: any SportDefinition) -> [String: String] {
        Dictionary(uniqueKeysWithValues: sport.statSchema.map { ($0.id, "") })
    }

    private func csv(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

struct SoccerMaxPrepsAdapter: MaxPrepsExportAdapter {
    private let mapping: [String: String] = [
        "goals": "Goals",
        "assists": "Assists",
        "shots": "Shots",
        "shotsOnTarget": "ShotsOnTarget",
        "minutesPlayed": "MinutesPlayed"
    ]

    func export(game: MatchRecord, team: Team, sport: any SportDefinition) -> String {
        GenericMaxPrepsAdapter().export(game: game, team: team, sport: sport)
    }

    func fieldMapping(for sport: any SportDefinition) -> [String: String] {
        mapping
    }
}

enum MaxPrepsAdapterFactory {
    static func adapter(for sport: any SportDefinition) -> MaxPrepsExportAdapter {
        if sport.id == SportCatalog.soccerID {
            return SoccerMaxPrepsAdapter()
        }
        return GenericMaxPrepsAdapter()
    }
}
