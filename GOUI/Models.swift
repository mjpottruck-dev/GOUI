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

    static var rosterPositions: [Position] {
        [.gk, .rb, .lb, .cb, .rwb, .lwb, .cdm, .cm, .cam, .rm, .lm, .rw, .lw, .st, .cf]
    }
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

    var lineLayout: [[Position]] {
        switch self {
        case .f433:
            return [[.rb, .cb, .cb, .lb], [.cm, .cm, .cm], [.rw, .st, .lw]]
        case .f442_flat:
            return [[.rb, .cb, .cb, .lb], [.rm, .cm, .cm, .lm], [.st, .st]]
        case .f442_diamond:
            return [[.rb, .cb, .cb, .lb], [.cdm, .cm, .cm, .cam], [.st, .st]]
        case .f4231:
            return [[.rb, .cb, .cb, .lb], [.cdm, .cdm], [.rm, .cam, .lm], [.st]]
        case .f4141:
            return [[.rb, .cb, .cb, .lb], [.cdm], [.rm, .cm, .cm, .lm], [.st]]
        case .f4312:
            return [[.rb, .cb, .cb, .lb], [.cm, .cm, .cm], [.cam], [.st, .st]]
        case .f451:
            return [[.rb, .cb, .cb, .lb], [.rm, .cm, .cm, .cm, .lm], [.st]]
        case .f424:
            return [[.rb, .cb, .cb, .lb], [.cm, .cm], [.rw, .st, .st, .lw]]
        case .f41212:
            return [[.rb, .cb, .cb, .lb], [.cdm], [.cm, .cm], [.cam], [.st, .st]]
        case .f4321:
            return [[.rb, .cb, .cb, .lb], [.cm, .cm, .cm], [.rw, .lw], [.st]]
        case .f4222:
            return [[.rb, .cb, .cb, .lb], [.cdm, .cdm], [.cam, .cam], [.st, .st]]
        case .f4311:
            return [[.rb, .cb, .cb, .lb], [.cm, .cm, .cm], [.cam], [.st]]
        case .f352:
            return [[.cb, .cb, .cb], [.rwb, .cm, .cm, .cm, .lwb], [.st, .st]]
        case .f343:
            return [[.cb, .cb, .cb], [.rm, .cm, .cm, .lm], [.rw, .st, .lw]]
        case .f3412:
            return [[.cb, .cb, .cb], [.rm, .cm, .cm, .lm], [.cam], [.st, .st]]
        case .f3421:
            return [[.cb, .cb, .cb], [.rwb, .cm, .cm, .lwb], [.rw, .lw], [.st]]
        case .f361:
            return [[.cb, .cb, .cb], [.rwb, .cm, .cm, .cm, .cm, .lwb], [.st]]
        case .f3241:
            return [[.cb, .cb, .cb], [.cdm, .cdm], [.rm, .cam, .cam, .lm], [.st]]
        case .f532:
            return [[.rwb, .cb, .cb, .cb, .lwb], [.cm, .cm, .cm], [.st, .st]]
        case .f523:
            return [[.rwb, .cb, .cb, .cb, .lwb], [.cm, .cm], [.rw, .st, .lw]]
        case .f541:
            return [[.rwb, .cb, .cb, .cb, .lwb], [.rm, .cm, .cm, .lm], [.st]]
        }
    }

    var slotPositions: [Position] {
        ([.gk] + lineLayout.flatMap { $0 })
    }
}

// MARK: - Season

struct Season: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var startDate: Date
    var endDate: Date

    init(id: UUID = UUID(), name: String, startDate: Date = Date(), endDate: Date = Date()) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Player

struct Player: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var number: Int
    var position: Position
    var secondaryPosition: Position? = nil

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
    var seasonID: UUID? = nil

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
    var primaryFormation: Formation = .f433

    var matches: [MatchRecord] = []
}
