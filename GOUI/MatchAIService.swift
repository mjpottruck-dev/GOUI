import Foundation

/// Shared service for calling the Anthropic API for match analysis features.
/// Handles caching via UserDefaults keyed by match/team ID.
enum MatchAIService {

    // MARK: - API Call

    static func generate(systemPrompt: String, userMessage: String) async throws -> String {
        guard ProAccess.isPro else { throw AIError.proRequired } // backstop; UI shows the paywall first
        let apiKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
        guard !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String,
              !text.isEmpty
        else {
            throw AIError.parseError
        }

        return text
    }

    // MARK: - Cache

    static func cachedText(forKey key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func cacheText(_ text: String, forKey key: String) {
        UserDefaults.standard.set(text, forKey: key)
    }

    // MARK: - Match Data Context Builder

    static func buildMatchContext(match: MatchRecord, team: Team, players: [Player], includeTimingDetail: Bool = false) -> String {
        var lines: [String] = []

        lines.append("Team: \(team.name)")
        lines.append("Opponent: \(match.opponent)")
        lines.append("Final Score: \(match.goalsFor) - \(match.goalsAgainst)")
        lines.append("Match Duration: \(match.secondsElapsed / 60) minutes")
        if !match.venue.isEmpty { lines.append("Venue: \(match.venue)") }

        // Goal scorers with minutes
        let goals = match.events.filter { $0.kind == .goal || $0.kind == .pkMade }
        if goals.isEmpty {
            lines.append("Goals: None")
        } else {
            lines.append("Goals:")
            for g in goals {
                let min = g.seconds / 60
                var desc = "  \(min)' - \(g.title)"
                if let d = g.detail, !d.isEmpty { desc += " (\(d))" }
                lines.append(desc)
            }
        }

        // Assists
        let assistEvents = goals.filter { $0.detail?.lowercased().contains("assist") == true }
        if !assistEvents.isEmpty {
            lines.append("Assists: \(assistEvents.compactMap { $0.detail }.joined(separator: ", "))")
        }

        // Aggregate stats
        var totalShots = 0, totalSOT = 0, totalSaves = 0, totalYellow = 0, totalRed = 0
        for (_, line) in match.playerStats {
            totalShots += line.shots
            totalSOT += line.shotsOnTarget
            totalSaves += line.saves
            totalYellow += line.yellowCards
            totalRed += line.redCards
        }
        lines.append("Total Shots: \(totalShots)")
        lines.append("Shots on Target: \(totalSOT)")
        lines.append("Saves: \(totalSaves)")
        lines.append("Goals Conceded: \(match.goalsAgainst)")

        // Cards
        let cardEvents = match.events.filter { $0.kind == .card }
        if cardEvents.isEmpty {
            lines.append("Cards: None")
        } else {
            lines.append("Cards:")
            for c in cardEvents {
                let min = c.seconds / 60
                lines.append("  \(min)' - \(c.title) (\(c.detail ?? ""))")
            }
        }

        // Substitutions
        let subEvents = match.events.filter { $0.title.lowercased().contains("sub") || $0.title.lowercased().contains("line change") }
        if subEvents.isEmpty {
            lines.append("Substitutions: None")
        } else {
            lines.append("Substitutions:")
            for s in subEvents {
                let min = s.seconds / 60
                lines.append("  \(min)' - \(s.title): \(s.detail ?? "")")
            }
        }

        // Extended timing detail for insights
        if includeTimingDetail {
            let halfwaySeconds = match.secondsElapsed / 2
            let firstHalfGoals = goals.filter { $0.seconds <= halfwaySeconds }.count
            let secondHalfGoals = goals.filter { $0.seconds > halfwaySeconds }.count
            lines.append("1st Half Goals: \(firstHalfGoals)")
            lines.append("2nd Half Goals: \(secondHalfGoals)")

            // Shot conversion rate
            if totalShots > 0 {
                let rate = Int(round(Double(match.goalsFor) / Double(totalShots) * 100))
                lines.append("Shot Conversion Rate: \(rate)%")
            }

            // Save percentage
            let totalFaced = totalSaves + match.goalsAgainst
            if totalFaced > 0 {
                let savePct = Int(round(Double(totalSaves) / Double(totalFaced) * 100))
                lines.append("Save Percentage: \(savePct)%")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Season Context Builder

    static func buildSeasonContext(team: Team, lastNMatches: Int = 3) -> String {
        var lines: [String] = []
        let recent = Array(team.matches.prefix(lastNMatches))

        lines.append("Team: \(team.name)")

        let allMatches = team.matches
        let wins = allMatches.filter { $0.goalsFor > $0.goalsAgainst }.count
        let draws = allMatches.filter { $0.goalsFor == $0.goalsAgainst }.count
        let losses = allMatches.filter { $0.goalsFor < $0.goalsAgainst }.count
        lines.append("Season Record: \(wins)W - \(draws)D - \(losses)L (\(allMatches.count) matches)")

        lines.append("\nLast \(recent.count) Matches:")
        for m in recent {
            let result: String
            if m.goalsFor > m.goalsAgainst { result = "W" }
            else if m.goalsFor < m.goalsAgainst { result = "L" }
            else { result = "D" }
            lines.append("  vs \(m.opponent): \(m.goalsFor)-\(m.goalsAgainst) (\(result))")
        }

        // Top scorer
        var goalsByPlayer: [UUID: Int] = [:]
        for match in allMatches {
            for (pid, stat) in match.playerStats {
                goalsByPlayer[pid, default: 0] += stat.goals
            }
        }
        if let topID = goalsByPlayer.max(by: { $0.value < $1.value })?.key,
           let topPlayer = team.players.first(where: { $0.id == topID }) {
            lines.append("Top Scorer: \(topPlayer.name) (\(goalsByPlayer[topID]!) goals)")
        }

        // GK save percentage
        var totalSaves = 0, totalConceded = 0
        for match in allMatches {
            for (pid, stat) in match.playerStats {
                if team.players.first(where: { $0.id == pid })?.position == .gk {
                    totalSaves += stat.saves
                    totalConceded += stat.goalsConceded
                }
            }
        }
        let totalFaced = totalSaves + totalConceded
        if totalFaced > 0 {
            let pct = Int(round(Double(totalSaves) / Double(totalFaced) * 100))
            lines.append("GK Save Percentage: \(pct)%")
        }

        // Streaks
        let last5 = Array(allMatches.prefix(5))
        let form = last5.map { m -> String in
            if m.goalsFor > m.goalsAgainst { return "W" }
            else if m.goalsFor < m.goalsAgainst { return "L" }
            else { return "D" }
        }
        if !form.isEmpty {
            lines.append("Recent Form: \(form.joined(separator: "-"))")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Errors

    enum AIError: LocalizedError {
        case noAPIKey
        case parseError
        case proRequired

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "Add your Anthropic API key in Settings."
            case .parseError: return "Couldn't generate summary. Check your connection and try again."
            case .proRequired: return "AI recaps are part of GoalStats Pro."
            }
        }
    }
}
