import Foundation

enum MaxPrepsExport {
    static let teamFields: [String] = [
        "Jersey",
        "Goals",
        "Assists",
        "Shots",
        "ShotsOnTarget",
        "MinutesPlayed",
        "PKG",
        "PKA"
    ]

    static let keeperFields: [String] = [
        "Jersey",
        "MinutesPlayed",
        "GoalsSaved",
        "PKSaved",
        "PKConceded",
        "Conceded"
    ]

    static func text(fields: [String], rows: [[String]]) -> String {
        var lines: [String] = [""]
        lines.append(fields.joined(separator: "|"))
        lines.append(contentsOf: rows.map { $0.joined(separator: "|") })
        return lines.joined(separator: "\n")
    }

    static func teamRows(
        players: [Player],
        stats: [UUID: PlayerStatLine],
        seconds: [UUID: Int]
    ) -> [[String]] {
        // Players who actually played. Keepers are on the keeper sheet; they're also
        // listed here only if they have field stats (e.g. a keeper who scored).
        let roster = sortedPlayers(players.filter { p in
            let line = stats[p.id] ?? PlayerStatLine()
            let played = (seconds[p.id] ?? 0) > 0
            let hasFieldStats = line.goals + line.assists + line.shots + line.pkAttempts > 0
            return p.position == .gk ? hasFieldStats : (played || hasFieldStats)
        })
        return roster.map { player in
            let line = stats[player.id] ?? PlayerStatLine()
            let minutes = (seconds[player.id] ?? 0) / 60
            return [
                jerseyValue(for: player),
                "\(line.goals)",
                "\(line.assists)",
                "\(line.shots)",
                "\(line.shotsOnTarget)",
                "\(minutes)",
                "\(line.pkGoals)",
                "\(line.pkAttempts)"
            ]
        }
    }

    static func keeperRows(
        players: [Player],
        stats: [UUID: PlayerStatLine],
        seconds: [UUID: Int]
    ) -> [[String]] {
        let keepers = sortedPlayers(players.filter { $0.position == .gk && (seconds[$0.id] ?? 0) > 0 })
        return keepers.map { player in
            let line = stats[player.id] ?? PlayerStatLine()
            let minutes = (seconds[player.id] ?? 0) / 60
            return [
                jerseyValue(for: player),
                "\(minutes)",
                "\(line.saves)",
                "\(line.pkSaved)",
                "\(line.pkConceded)",
                "\(line.goalsConceded)"
            ]
        }
    }

    static func writeTempTXT(filename: String, contents: String) throws -> URL {
        let safeName = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).txt")

        try contents.data(using: .utf8)?.write(to: url, options: [.atomic])
        return url
    }

    static func sanitizedFilename(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Match" }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let cleaned = String(trimmed.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        })
        var sanitized = cleaned.replacingOccurrences(of: " ", with: "_")
        while sanitized.contains("__") {
            sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
        }
        return sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    private static func jerseyValue(for player: Player) -> String {
        player.jersey.isEmpty ? "\(player.number)" : player.jersey
    }

    private static func sortedPlayers(_ players: [Player]) -> [Player] {
        players.sorted { ($0.number, $0.name) < ($1.number, $1.name) }
    }
}
