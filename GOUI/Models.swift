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

    // 7v7 (6 outfield + 1 GK)
    case f7_231 = "2-3-1"
    case f7_321 = "3-2-1"
    case f7_312 = "3-1-2"
    case f7_2121 = "2-1-2-1"
    case f7_132 = "1-3-2"

    // 9v9 (8 outfield + 1 GK)
    case f9_332 = "3-3-2"
    case f9_323 = "3-2-3"
    case f9_242 = "2-4-2"
    case f9_3131 = "3-1-3-1"
    case f9_2312 = "2-3-1-2"
    case f9_341 = "3-4-1"

    var id: String { rawValue }

    var familyLabel: String {
        switch self {
        case .f442_flat, .f442_diamond, .f433, .f4231, .f4141, .f4312, .f451, .f424, .f41212, .f4321, .f4222, .f4311:
            return "Back-four system"
        case .f352, .f343, .f3412, .f3421, .f361, .f3241:
            return "Back-three / wingbacks"
        case .f532, .f523, .f541:
            return "Five-at-the-back"
        case .f7_231, .f7_321, .f7_312, .f7_2121, .f7_132:
            return "7v7 system"
        case .f9_332, .f9_323, .f9_242, .f9_3131, .f9_2312, .f9_341:
            return "9v9 system"
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

        // 7v7 formations (6 outfield)
        case .f7_231:
            return [[.cb, .cb], [.rm, .cm, .lm], [.st]]
        case .f7_321:
            return [[.cb, .cb, .cb], [.cm, .cm], [.st]]
        case .f7_312:
            return [[.cb, .cb, .cb], [.cm], [.st, .st]]
        case .f7_2121:
            return [[.cb, .cb], [.cm], [.rm, .lm], [.st]]
        case .f7_132:
            return [[.cb], [.rm, .cm, .lm], [.st, .st]]

        // 9v9 formations (8 outfield)
        case .f9_332:
            return [[.cb, .cb, .cb], [.rm, .cm, .lm], [.st, .st]]
        case .f9_323:
            return [[.cb, .cb, .cb], [.cm, .cm], [.rw, .st, .lw]]
        case .f9_242:
            return [[.cb, .cb], [.rm, .cm, .cm, .lm], [.st, .st]]
        case .f9_3131:
            return [[.cb, .cb, .cb], [.cm], [.rm, .cm, .lm], [.st]]
        case .f9_2312:
            return [[.cb, .cb], [.rm, .cm, .lm], [.cam], [.st, .st]]
        case .f9_341:
            return [[.cb, .cb, .cb], [.rm, .cm, .cm, .lm], [.st]]
        }
    }

    var slotPositions: [Position] {
        ([.gk] + lineLayout.flatMap { $0 })
    }

    var playerCount: Int {
        switch self {
        case .f7_231, .f7_321, .f7_312, .f7_2121, .f7_132:
            return 7
        case .f9_332, .f9_323, .f9_242, .f9_3131, .f9_2312, .f9_341:
            return 9
        default:
            return 11
        }
    }

    static func defaultFormation(for fieldSize: Int) -> Formation {
        switch fieldSize {
        case 7:  return .f7_231
        case 9:  return .f9_332
        default: return .f442_flat
        }
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
    var jersey: String = ""
    var position: Position
    var secondaryPosition: Position? = nil
    var positionName: String? = nil
    var isGoalie: Bool? = nil
    var notes: String? = nil

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

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

    // Penalty kicks taken by this player (for MaxPreps PKG / PKA)
    var pkGoals: Int = 0
    var pkAttempts: Int = 0
}

extension Player {
    func displayPosition(for sport: SportDefinition) -> String? {
        guard sport.supportsPositions else { return nil }
        if let positionName {
            return positionName
        }
        return position.rawValue
    }

    var derivedIsGoalie: Bool {
        if let isGoalie {
            return isGoalie
        }
        return position == .gk
    }
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

    var pkGoals: Int = 0
    var pkAttempts: Int = 0

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

    var venue: String = ""

    var playerSeconds: [UUID: Int] = [:]
    var playerStats: [UUID: PlayerStatLine] = [:]

    /// Timeline events saved with the match (backward-compatible default)
    var events: [MatchEvent] = []
}

// MARK: - Team

struct Team: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var players: [Player] = []

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var fieldSize: Int = 11
    var startingOnFieldIDs: [UUID] = []
    var primaryFormation: Formation = .f433
    var primaryGoalkeeperID: UUID? = nil
    var secondaryGoalkeeperID: UUID? = nil
    var thirdGoalkeeperID: UUID? = nil

    var matches: [MatchRecord] = []

    // Sync bookkeeping: IDs removed from this team, so iCloud merges on another
    // device don't bring them back.
    var deletedMatchIDs: [UUID] = []
    var deletedPlayerIDs: [UUID] = []

    /// True for the sample team created on first launch; not uploaded to iCloud
    /// until it has real matches.
    var isDemo: Bool = false

    /// Match format: 2 = halves, 4 = quarters.
    var periodCount: Int = 2
    /// Length of each period in minutes; 0 = no set length (clock just counts up).
    var periodMinutes: Int = 0
}

extension Team {
    static func goalkeeperDepthIDs(
        from players: [Player],
        currentPrimary: UUID? = nil,
        currentSecondary: UUID? = nil,
        currentThird: UUID? = nil
    ) -> (primary: UUID?, secondary: UUID?, third: UUID?) {
        let goalkeepers = players.filter { $0.position == .gk }
        guard !goalkeepers.isEmpty else { return (nil, nil, nil) }

        let sortedGoalkeepers = goalkeepers.sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.number < rhs.number
        }
        let sortedIDs = sortedGoalkeepers.map(\.id)

        var ordered: [UUID] = []
        for id in [currentPrimary, currentSecondary, currentThird].compactMap({ $0 }) {
            if sortedIDs.contains(id), !ordered.contains(id) {
                ordered.append(id)
            }
        }

        for id in sortedIDs where !ordered.contains(id) {
            ordered.append(id)
            if ordered.count == 3 { break }
        }

        let primary = ordered.indices.contains(0) ? ordered[0] : nil
        let secondary = ordered.indices.contains(1) ? ordered[1] : nil
        let third = ordered.indices.contains(2) ? ordered[2] : nil
        return (primary, secondary, third)
    }

    static func primaryGoalkeeperID(from players: [Player], current: UUID? = nil) -> UUID? {
        goalkeeperDepthIDs(from: players, currentPrimary: current).primary
    }
}

// MARK: - Tolerant decoding
//
// Swift's synthesized Codable REQUIRES every non-optional key to be present, even
// when the property has a default value. So adding any new field (like `venue` or
// `events` on MatchRecord) makes every file saved by an older build fail to load.
// These decoders fill in defaults for missing keys, skip only the individual bad
// items in a list, and record any repair in `DecodeRepairs` so TeamStore can back
// the original file up before saving over it. Encoding stays synthesized.
// Rule for the future: new stored fields get a line here too.

/// Counts values that were present in a saved file but could not be read.
/// TeamStore resets it before loading and backs the file up if it's non-zero.
enum DecodeRepairs {
    static var count = 0
}

/// Decodes anything, so a bad element in an unkeyed container can be skipped.
private struct SkippedElement: Decodable {
    init(from decoder: Decoder) throws {}
}

extension KeyedDecodingContainer {
    /// Decodes `key` if present and readable. Missing → `fallback` (expected after an
    /// update adds a field). Present but unreadable → `fallback` and a recorded repair.
    func value<T: Decodable>(_ key: Key, or fallback: @autoclosure () -> T) -> T {
        guard contains(key) else { return fallback() }
        do {
            if let decoded = try decodeIfPresent(T.self, forKey: key) {
                return decoded
            }
            return fallback()
        } catch {
            DecodeRepairs.count += 1
            print("⚠️ Could not read \(key.stringValue); using default:", error)
            return fallback()
        }
    }

    /// Decodes an array element by element, keeping every readable element and
    /// skipping (and recording) only the unreadable ones.
    func lossyArray<T: Decodable>(_ key: Key) -> [T] {
        guard contains(key), (try? decodeNil(forKey: key)) == false else { return [] }
        guard var list = try? nestedUnkeyedContainer(forKey: key) else {
            DecodeRepairs.count += 1
            return []
        }
        var result: [T] = []
        while !list.isAtEnd {
            if let element = try? list.decode(T.self) {
                result.append(element)
            } else {
                DecodeRepairs.count += 1
                print("⚠️ Skipped an unreadable item in \(key.stringValue)")
                if (try? list.decode(SkippedElement.self)) == nil { break }
            }
        }
        return result
    }
}

extension Season {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            name: c.value(.name, or: "Season"),
            startDate: c.value(.startDate, or: Date()),
            endDate: c.value(.endDate, or: Date())
        )
    }
}

extension Player {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id: UUID = try c.decode(UUID.self, forKey: .id)
        let position: Position = c.value(.position, or: Position.cm)
        let secondaryPosition: Position? = c.value(.secondaryPosition, or: nil)
        let positionName: String? = c.value(.positionName, or: nil)
        let isGoalie: Bool? = c.value(.isGoalie, or: nil)
        let notes: String? = c.value(.notes, or: nil)
        self.init(
            id: id,
            name: c.value(.name, or: ""),
            number: c.value(.number, or: 0),
            jersey: c.value(.jersey, or: ""),
            position: position,
            secondaryPosition: secondaryPosition,
            positionName: positionName,
            isGoalie: isGoalie,
            notes: notes
        )
        createdAt = c.value(.createdAt, or: Date.distantPast)
        updatedAt = c.value(.updatedAt, or: Date.distantPast)
        secondsPlayed = c.value(.secondsPlayed, or: 0)
        goals = c.value(.goals, or: 0)
        assists = c.value(.assists, or: 0)
        shots = c.value(.shots, or: 0)
        shotsOnTarget = c.value(.shotsOnTarget, or: 0)
        yellowCards = c.value(.yellowCards, or: 0)
        redCards = c.value(.redCards, or: 0)
        saves = c.value(.saves, or: 0)
        goalsConceded = c.value(.goalsConceded, or: 0)
        pkFaced = c.value(.pkFaced, or: 0)
        pkSaved = c.value(.pkSaved, or: 0)
        pkConceded = c.value(.pkConceded, or: 0)
        pkGoals = c.value(.pkGoals, or: 0)
        pkAttempts = c.value(.pkAttempts, or: 0)
    }
}

extension PlayerStatLine {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        id = c.value(.id, or: UUID())
        goals = c.value(.goals, or: 0)
        assists = c.value(.assists, or: 0)
        shots = c.value(.shots, or: 0)
        shotsOnTarget = c.value(.shotsOnTarget, or: 0)
        yellowCards = c.value(.yellowCards, or: 0)
        redCards = c.value(.redCards, or: 0)
        saves = c.value(.saves, or: 0)
        goalsConceded = c.value(.goalsConceded, or: 0)
        pkFaced = c.value(.pkFaced, or: 0)
        pkSaved = c.value(.pkSaved, or: 0)
        pkConceded = c.value(.pkConceded, or: 0)
        pkGoals = c.value(.pkGoals, or: 0)
        pkAttempts = c.value(.pkAttempts, or: 0)
    }
}

extension MatchRecord {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id: UUID = try c.decode(UUID.self, forKey: .id)
        let seasonID: UUID? = c.value(.seasonID, or: nil)
        let playerSeconds: [UUID: Int] = c.value(.playerSeconds, or: [:])
        let playerStats: [UUID: PlayerStatLine] = c.value(.playerStats, or: [:])
        let events: [MatchEvent] = c.lossyArray(.events)
        self.init(id: id)
        date = c.value(.date, or: Date.distantPast)
        opponent = c.value(.opponent, or: "")
        title = c.value(.title, or: "")
        notes = c.value(.notes, or: "")
        goalsFor = c.value(.goalsFor, or: 0)
        goalsAgainst = c.value(.goalsAgainst, or: 0)
        secondsElapsed = c.value(.secondsElapsed, or: 0)
        fieldSize = c.value(.fieldSize, or: 7)
        self.seasonID = seasonID
        venue = c.value(.venue, or: "")
        self.playerSeconds = playerSeconds
        self.playerStats = playerStats
        self.events = events
    }
}

extension Team {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id: UUID = try c.decode(UUID.self, forKey: .id)
        let name: String = c.value(.name, or: "Team")
        let fieldSize: Int = c.value(.fieldSize, or: 11)
        let formation: Formation = c.value(.primaryFormation, or: Formation.defaultFormation(for: fieldSize))
        let primaryGK: UUID? = c.value(.primaryGoalkeeperID, or: nil)
        let secondaryGK: UUID? = c.value(.secondaryGoalkeeperID, or: nil)
        let thirdGK: UUID? = c.value(.thirdGoalkeeperID, or: nil)
        let players: [Player] = c.lossyArray(.players)
        let matches: [MatchRecord] = c.lossyArray(.matches)
        self.init(id: id, name: name)
        self.players = players
        createdAt = c.value(.createdAt, or: Date.distantPast)
        // distantPast, not now: a copy with no timestamp must never look newest in a sync.
        updatedAt = c.value(.updatedAt, or: Date.distantPast)
        self.fieldSize = fieldSize
        startingOnFieldIDs = c.value(.startingOnFieldIDs, or: [])
        primaryFormation = formation
        primaryGoalkeeperID = primaryGK
        secondaryGoalkeeperID = secondaryGK
        thirdGoalkeeperID = thirdGK
        self.matches = matches
        deletedMatchIDs = c.value(.deletedMatchIDs, or: [])
        deletedPlayerIDs = c.value(.deletedPlayerIDs, or: [])
        isDemo = c.value(.isDemo, or: false)
        periodCount = c.value(.periodCount, or: 2)
        periodMinutes = c.value(.periodMinutes, or: 0)
    }
}
