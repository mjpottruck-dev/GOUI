import SwiftUI

enum SportSeason: String, CaseIterable {
    case fall
    case winter
    case spring
}

enum SportType: String, CaseIterable {
    case teamGame
    case individualMeet
    case dualIndividual
}

enum SegmentKind: String, CaseIterable {
    case quarters
    case halves
    case periods
    case sets
    case innings
    case holes
    case events
}

struct SegmentDefinition {
    let name: String
    let durationSeconds: Int?
    let count: Int
}

enum StatFormat: String, CaseIterable {
    case count
    case time
    case distance
    case score
}

protocol SportDefinition {
    var id: String { get }
    var displayName: String { get }
    var season: SportSeason { get }
    var supportsTimer: Bool { get }
    var supportsGoalie: Bool { get }
    var supportsPositions: Bool { get }
    var supportsCourtOverlay: Bool { get }
    var supportsTeamScore: Bool { get }
    var supportsPeriods: Bool { get }
    var supportsHoles: Bool { get }
    var defaultHoleCount: Int { get }
    var scoringMode: ScoringMode { get }
    var periods: [PeriodDefinition] { get }
    var statSchema: [StatType] { get }
    var eventTypes: [EventType] { get }
    var courtLayout: CourtLayoutDefinition { get }
    var scoringRules: ScoringRules { get }

    var sportType: SportType { get }
    var segmentKind: SegmentKind { get }
    var defaultSegments: [SegmentDefinition] { get }
    var statTypes: [StatType] { get }
    var eventTypesTeam: [EventType] { get }
    var eventTypesGoalie: [EventType] { get }
}

struct PeriodDefinition {
    let name: String
    let duration: TimeInterval
    let maxCount: Int
}

struct StatType: Identifiable {
    let id: String
    let displayName: String
    let shortLabel: String?
    let countsForTeam: Bool
    let countsForPlayer: Bool
}

extension StatType {
    var format: StatFormat { .count }
}

enum EventUIAction: String {
    case direct
    case assist
    case shot
    case shotPenalty
    case card
    case holeEntry
}

struct ShotOutcomeStats {
    let onTarget: [String: Int]
    let offTarget: [String: Int]
}

struct EventType: Identifiable {
    let id: String
    let label: String
    let iconName: String
    let requiresPlayer: Bool
    let secondaryPlayerOptional: Bool
    let isGoalieOnly: Bool
    let usesGoalie: Bool
    let uiAction: EventUIAction
    let primaryStatChanges: [String: Int]
    let secondaryStatChanges: [String: Int]
    let shotOutcomeStats: ShotOutcomeStats?
    let cardStatChanges: [CardType: [String: Int]]
}

enum CourtLayoutKind {
    case soccer
    case waterPolo
    case basketball
    case none
}

struct CourtLayoutDefinition {
    let kind: CourtLayoutKind
}

struct ScoringRules {
    let scoreLabel: String
    let primaryStatID: String
    let teamEventPoints: [String: Int]
    let opponentEventPoints: [String: Int]
    let periodEventPoints: [String: Int]
    let opponentPeriodEventPoints: [String: Int]

    func points(for eventID: String, isOpponent: Bool) -> Int? {
        if isOpponent {
            return opponentEventPoints[eventID]
        }
        return teamEventPoints[eventID]
    }

    func periodPoints(for eventID: String, isOpponent: Bool) -> Int? {
        if isOpponent {
            return opponentPeriodEventPoints[eventID]
        }
        return periodEventPoints[eventID]
    }
}

enum ScoringMode {
    case teamVsTeam
    case individual
    case dualIndividual
}

enum SportCatalog {
    static let soccerID = "soccer"
    static let waterPoloID = "waterpolo"
    static let legacyWaterPoloID = "water_polo"
    static let basketballID = "basketball"
    static let volleyballID = "volleyball"
    static let tennisID = "tennis"
    static let golfID = "golf"
    static let footballID = "football"
    static let fieldHockeyID = "field_hockey"
    static let crossCountryID = "cross_country"
    static let wrestlingID = "wrestling"
    static let swimmingID = "swimming"
    static let iceHockeyID = "ice_hockey"
    static let baseballID = "baseball"
    static let softballID = "softball"
    static let lacrosseID = "lacrosse"
    static let trackID = "track"
    static let defaultSportID = soccerID
    private static var registry: [String: any SportDefinition] = [:]

    @discardableResult
    static func register(_ sport: any SportDefinition) -> any SportDefinition {
        registry[sport.id] = sport
        return sport
    }

    static var all: [any SportDefinition] {
        registry.values.sorted { $0.displayName < $1.displayName }
    }

    static var defaultSport: any SportDefinition {
        sport(for: defaultSportID)
    }

    static func sport(for id: String?) -> any SportDefinition {
        let resolvedID = id ?? defaultSportID
        let normalizedID = resolvedID == legacyWaterPoloID ? waterPoloID : resolvedID
        return registry[normalizedID] ?? registry[defaultSportID] ?? SoccerSport()
    }
}

extension SportDefinition {
    var sportType: SportType {
        switch scoringMode {
        case .teamVsTeam: return .teamGame
        case .individual: return .individualMeet
        case .dualIndividual: return .dualIndividual
        }
    }

    var segmentKind: SegmentKind {
        if supportsHoles { return .holes }
        if supportsPeriods {
            if id == SportCatalog.volleyballID || id == SportCatalog.tennisID {
                return .sets
            }
            return .periods
        }
        return .events
    }

    var defaultSegments: [SegmentDefinition] {
        if supportsPeriods {
            return periods.map { SegmentDefinition(name: $0.name, durationSeconds: Int($0.duration), count: $0.maxCount) }
        }
        if supportsHoles {
            return [SegmentDefinition(name: "Hole", durationSeconds: nil, count: defaultHoleCount)]
        }
        return [SegmentDefinition(name: "Event", durationSeconds: nil, count: 1)]
    }

    var statTypes: [StatType] { statSchema }
    var eventTypesTeam: [EventType] { eventTypes.filter { !$0.isGoalieOnly } }
    var eventTypesGoalie: [EventType] { eventTypes.filter { $0.isGoalieOnly } }
}
