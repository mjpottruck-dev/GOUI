import Foundation

/// Which AI feature is calling. The backend picks the model and token cap per feature.
enum AIFeature: String {
    case recap, insight, season, trends, roster
}

/// Every AI request goes through the GoalStats backend, which holds the
/// Anthropic key and checks the coach's Pro subscription. The app never
/// carries an API key.
enum AIClient {
    /// Hosted GoalStats API (Render service "goalstats-api").
    static let productionBaseURL = URL(string: "https://goalstats-api-v8zi.onrender.com")!

    /// Debug builds: Settings > Debug can point at a local server.
    static let debugURLKey = "ai_backend_url"
    /// Debug builds: matches DEV_API_KEY on a local server so "Simulate Pro" works.
    static let debugDevKey = "ai_dev_key"
    /// Latest StoreKit signed transaction for Pro (written by ProStore).
    static let transactionKey = "pro_transaction_jws"

    static var baseURL: URL {
        #if DEBUG
        if let s = UserDefaults.standard.string(forKey: debugURLKey),
           let url = URL(string: s.trimmingCharacters(in: .whitespaces)), !s.isEmpty {
            return url
        }
        return URL(string: "http://localhost:3000")!
        #else
        return productionBaseURL
        #endif
    }

    enum Failure: LocalizedError {
        case proRequired, rateLimited, unavailable, badResponse

        var errorDescription: String? {
            switch self {
            case .proRequired: return "This is a GoalStats Pro feature. Check your subscription in Settings."
            case .rateLimited: return "You've hit the AI limit for now. Try again in a few minutes."
            case .unavailable: return "AI is unavailable right now. Check your connection and try again."
            case .badResponse: return "Couldn't generate a response. Try again."
            }
        }
    }

    /// Sends an Anthropic-style Messages request through the backend and returns the text.
    static func send(
        feature: AIFeature,
        system: String? = nil,
        messages: [[String: Any]],
        maxTokens: Int? = nil
    ) async throws -> String {
        do {
            return try await attempt(feature: feature, system: system, messages: messages, maxTokens: maxTokens)
        } catch Failure.proRequired {
            // The saved transaction may be stale (e.g. just renewed). Refresh once and retry.
            await ProStore.shared.refreshEntitlements()
            guard ProAccess.isPro else { throw Failure.proRequired }
            return try await attempt(feature: feature, system: system, messages: messages, maxTokens: maxTokens)
        }
    }

    /// Convenience for a single user message.
    static func send(feature: AIFeature, system: String? = nil, prompt: String, maxTokens: Int? = nil) async throws -> String {
        try await send(feature: feature, system: system, messages: [["role": "user", "content": prompt]], maxTokens: maxTokens)
    }

    private static func attempt(feature: AIFeature, system: String?, messages: [[String: Any]], maxTokens: Int?) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("ai/messages"))
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        if let jws = UserDefaults.standard.string(forKey: transactionKey), !jws.isEmpty {
            request.setValue("Bearer \(jws)", forHTTPHeaderField: "authorization")
        }
        #if DEBUG
        if let dev = UserDefaults.standard.string(forKey: debugDevKey), !dev.isEmpty {
            request.setValue(dev, forHTTPHeaderField: "x-dev-key")
        }
        #endif

        var body: [String: Any] = ["feature": feature.rawValue, "messages": messages]
        if let system { body["system"] = system }
        if let maxTokens { body["max_tokens"] = maxTokens }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw Failure.unavailable
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String, !text.isEmpty else { throw Failure.badResponse }
            return text
        case 401, 402: throw Failure.proRequired
        case 429: throw Failure.rateLimited
        default: throw Failure.unavailable
        }
    }

    /// Strips ```json fences the model sometimes adds around JSON.
    static func stripCodeFences(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let nl = t.firstIndex(of: "\n") { t = String(t[t.index(after: nl)...]) }
            if t.hasSuffix("```") { t = String(t.dropLast(3)) }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
