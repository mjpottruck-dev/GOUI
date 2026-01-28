import Foundation

// MARK: - Position

enum Position: String, CaseIterable, Identifiable, Codable {
    // Core
    case gk = "GK"

    // Back line
    case rb = "RB"
    case lb = "LB"
    case cb = "CB"
    case rwb = "RWB"
    case lwb = "LWB"

    // Midfield
    case dm = "DM"
    case cdm = "CDM"
    case cm = "CM"
    case am = "AM"
    case cam = "CAM"
    case rm = "RM"
    case lm = "LM"

    // Attack
    case rw = "RW"
    case lw = "LW"
    case st = "ST"
    case cf = "CF"

    // Legacy (keep so old players don’t break)
    case def = "DEF"
    case mid = "MID"
    case fw  = "FW"

    var id: String { rawValue }
}

// MARK: - Formation

enum Formation: String, CaseIterable, Identifiable, Codable {
    // classic back four
    case f442_flat = "4-4-2 (Flat)"
    case f442_diamond = "4-4-2 (Diamond)"
    case f433 = "4-3-3"
    case f4231 = "4-2-3-1"
    case f4141 = "4-1-4-1"
    case f4312 = "4-3-1-2"
    case f451 = "4-5-1"
    case f424 = "4-2-4"
    case f41212 = "4-1-2-1-2 (Narrow)"
    case f4321 = "4-3-2-1"
    case f4222 = "4-2-2-2"
    case f4311 = "4-3-1-1"

    // back three / wingbacks
    case f352 = "3-5-2"
    case f343 = "3-4-3"
    case f3412 = "3-4-1-2"
    case f3421 = "3-4-2-1"
    case f361 = "3-6-1"
    case f3241 = "3-2-4-1"

    // five at back
    case f532 = "5-3-2"
    case f523 = "5-2-3"
    case f541 = "5-4-1"

    var id: String { rawValue }

    var familyLabel: String {
        switch self {
        case .f442_flat, .f442_diamond, .f433, .f4231, .f4141, .f4312, .f451, .f424, .f41212, .f4321, .f4222, .f4311:
            return "Back-four system"
        case .f352, .f343, .f3412, .f3421, .f361, .f3241:
            return "Back-three / wingbacks"
        case .f532, .f523, .f541:
            return "Five-at-the-back"
        }
    }
}

// MARK: - Player

struct Player: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var number: Int
    var position: Position

    var secondsPlayed: Int = 0

    var goals: Int = 0
    var assists: Int = 0
    var shots: Int = 0
    var shotsOnTarget: Int = 0
    var yellowCards: Int = 0
    var redCards: Int = 0

    var saves: Int = 0
    var goalsConceded: Int = 0
    var pkFaced: Int = 0
    var pkSaved: Int = 0
    var pkConceded: Int = 0
}

// MARK: - PlayerStatLine

struct PlayerStatLine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()

    var goals: Int = 0
    var assists: Int = 0
    var shots: Int = 0
    var shotsOnTarget: Int = 0
    var yellowCards: Int = 0
    var redCards: Int = 0

    var saves: Int = 0
    var goalsConceded: Int = 0
    var pkFaced: Int = 0
    var pkSaved: Int = 0
    var pkConceded: Int = 0

    init() {}

    static func fromPlayer(_ player: Player) -> PlayerStatLine {
        PlayerStatLine()
    }
}

// MARK: - MatchRecord

struct MatchRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()

    var date: Date = Date()
    var opponent: String = ""
    var title: String = ""
    var notes: String = ""

    var goalsFor: Int = 0
    var goalsAgainst: Int = 0

    var secondsElapsed: Int = 0
    var fieldSize: Int = 7

    var playerSeconds: [UUID: Int] = [:]
    var playerStats: [UUID: PlayerStatLine] = [:]
}

// MARK: - Team

struct Team: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var players: [Player] = []

    var fieldSize: Int = 7
    var startingOnFieldIDs: [UUID] = []

    var matches: [MatchRecord] = []
}

