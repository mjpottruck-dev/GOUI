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
        // Check for API key in UserDefaults or bundle
        let apiKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
        guard !apiKey.isEmpty else {
            return "Add your Anthropic API key in Settings to enable AI insights."
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 200,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let text = content.first?["text"] as? String {
            return text
        }

        return "Unable to analyze performance right now."
    }
}
