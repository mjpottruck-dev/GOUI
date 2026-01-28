import Foundation

extension MatchRecord {
    var uiOpponent: String { opponent }

    // IMPORTANT: optional to avoid “conditional binding must have Optional type”
    var uiDate: Date? { date }

    var uiDateText: String {
        guard let d = uiDate else { return "No date" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }

    var uiHomeScore: Int { goalsFor }
    var uiAwayScore: Int { goalsAgainst }

    var uiScoreText: String {
        "\(uiHomeScore) – \(uiAwayScore)"
    }
}

