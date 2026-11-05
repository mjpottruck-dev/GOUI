import Foundation

// MARK: - MatchActionKind

enum MatchActionKind: String, CaseIterable, Identifiable, Codable {
    case goal = "Goal"
    case shot = "Shot"
    case ownGoal = "Own Goal"
    case pkAttempt = "PK Attempt"
    case card = "Card"
    case save = "Save"
    case pkSave = "PK Save"
    case conceded = "Conceded"
    case pkConceded = "PK Conceded"
    case pkMade = "PK Made"
    case substitution = "Substitution"

    var id: String { rawValue }
}

// MARK: - MatchAction (for future event flow)

struct MatchAction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: MatchActionKind
    var seconds: Int

    // Optional links (future proof)
    var primaryPlayerID: UUID? = nil
    var secondaryPlayerID: UUID? = nil
    var isOnTarget: Bool? = nil

    init(kind: MatchActionKind, seconds: Int) {
        self.kind = kind
        self.seconds = seconds
    }
}

// MARK: - MatchEvent (timeline)

struct MatchEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: MatchActionKind
    var seconds: Int

    var title: String
    var detail: String?

    init(kind: MatchActionKind, seconds: Int, title: String, detail: String? = nil) {
        self.kind = kind
        self.seconds = seconds
        self.title = title
        self.detail = detail
    }
}


// Tolerant decoding (see Models.swift): a missing or unknown field never makes
// a saved match fail to load.
extension MatchEvent {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id: UUID = try c.decode(UUID.self, forKey: .id)
        let detail: String? = c.value(.detail, or: nil)
        self.init(
            kind: c.value(.kind, or: MatchActionKind.substitution),
            seconds: c.value(.seconds, or: 0),
            title: c.value(.title, or: ""),
            detail: detail
        )
        self.id = id
    }
}
