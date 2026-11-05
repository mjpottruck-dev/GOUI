import Foundation

@MainActor
final class PlayerTrendsService: ObservableObject {
    @Published var insight: String? = nil
    @Published var isLoading = false

    private var cache: [UUID: String] = [:]

    func fetchInsight(for player: Player, team: Team) async {
        guard ProAccess.isPro else { return } // AI player trends are Pro
        if let cached = cache[player.id] {
            insight = cached
            return
        }

        let recentMatches = team.matches.suffix(5)
        guard recentMatches.count >= 2 else {
            insight = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        var statsLines: [String] = []
        for match in recentMatches {
            let line = match.playerStats[player.id] ?? PlayerStatLine()
            let mins = (match.playerSeconds[player.id] ?? 0) / 60
            statsLines.append("vs \(match.opponent): \(line.goals)G \(line.assists)A \(line.shots)Sh \(line.saves)Sv \(mins)min")
        }

        let prompt = "You are a soccer analytics assistant. Given these last \(recentMatches.count) match stats for \(player.name) (\(player.position.rawValue)), provide 2-3 sentences about their form, patterns, and suggestions. Be specific and constructive.\n\nStats:\n\(statsLines.joined(separator: "\n"))"

        do {
            let result = try await callAnthropic(prompt: prompt)
            cache[player.id] = result
            insight = result
        } catch {
            insight = "Unable to analyze performance right now."
        }
    }

    private func callAnthropic(prompt: String) async throws -> String {
        try await AIClient.send(feature: .trends, prompt: prompt, maxTokens: 200)
    }
}
