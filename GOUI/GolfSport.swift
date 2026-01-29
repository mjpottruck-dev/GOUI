import Foundation

struct GolfSport: SportDefinition {
    let id = SportCatalog.golfID
    let displayName = "Golf"
    let season: SportSeason = .spring
    let supportsTimer = false
    let supportsGoalie = false
    let supportsPositions = false
    let supportsCourtOverlay = false
    let supportsTeamScore = false
    let supportsPeriods = false
    let supportsHoles = true
    let defaultHoleCount = 18
    let scoringMode: ScoringMode = .individual

    let periods: [PeriodDefinition] = []

    let statSchema: [StatType] = [
        StatType(id: "strokes", displayName: "Strokes", shortLabel: "STR", countsForTeam: false, countsForPlayer: true),
        StatType(id: "holesPlayed", displayName: "Holes Played", shortLabel: "H", countsForTeam: false, countsForPlayer: true),
        StatType(id: "putts", displayName: "Putts", shortLabel: "PUT", countsForTeam: false, countsForPlayer: true),
        StatType(id: "fairwaysHit", displayName: "Fairways Hit", shortLabel: "FW", countsForTeam: false, countsForPlayer: true),
        StatType(id: "greensInRegulation", displayName: "GIR", shortLabel: "GIR", countsForTeam: false, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "holeScore",
            label: "Record Hole",
            iconName: "flag.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .holeEntry,
            primaryStatChanges: [:],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "fairwayHit",
            label: "Fairway Hit",
            iconName: "checkmark.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["fairwaysHit": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "gir",
            label: "GIR",
            iconName: "leaf.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["greensInRegulation": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Strokes",
        primaryStatID: "strokes",
        teamEventPoints: [:],
        opponentEventPoints: [:],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _golfSportRegistration = SportCatalog.register(GolfSport())
