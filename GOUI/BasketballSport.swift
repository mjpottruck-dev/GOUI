import Foundation

struct BasketballSport: SportDefinition {
    let id = "basketball"
    let displayName = "Basketball"
    let season: SportSeason = .winter
    let supportsGoalie = false
    let supportsPositions = false

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "Q1", duration: 12 * 60, maxCount: 1),
        PeriodDefinition(name: "Q2", duration: 12 * 60, maxCount: 1),
        PeriodDefinition(name: "Q3", duration: 12 * 60, maxCount: 1),
        PeriodDefinition(name: "Q4", duration: 12 * 60, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "points", displayName: "Points", shortLabel: "PTS", countsForTeam: true, countsForPlayer: true),
        StatType(id: "twoPointMade", displayName: "2PT Made", shortLabel: "2PM", countsForTeam: true, countsForPlayer: true),
        StatType(id: "threePointMade", displayName: "3PT Made", shortLabel: "3PM", countsForTeam: true, countsForPlayer: true),
        StatType(id: "freeThrowMade", displayName: "Free Throw", shortLabel: "FT", countsForTeam: true, countsForPlayer: true),
        StatType(id: "rebound", displayName: "Rebound", shortLabel: "REB", countsForTeam: true, countsForPlayer: true),
        StatType(id: "assist", displayName: "Assist", shortLabel: "AST", countsForTeam: true, countsForPlayer: true),
        StatType(id: "steal", displayName: "Steal", shortLabel: "STL", countsForTeam: true, countsForPlayer: true),
        StatType(id: "block", displayName: "Block", shortLabel: "BLK", countsForTeam: true, countsForPlayer: true),
        StatType(id: "foul", displayName: "Foul", shortLabel: "F", countsForTeam: true, countsForPlayer: true),
        StatType(id: "turnover", displayName: "Turnover", shortLabel: "TO", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "twoPointMade",
            label: "2PT Made",
            iconName: "circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["points": 2, "twoPointMade": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "threePointMade",
            label: "3PT Made",
            iconName: "circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["points": 3, "threePointMade": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "freeThrowMade",
            label: "Free Throw",
            iconName: "circle.dashed",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["points": 1, "freeThrowMade": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "rebound",
            label: "Rebound",
            iconName: "arrow.up",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["rebound": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "assist",
            label: "Assist",
            iconName: "arrowshape.turn.up.right.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["assist": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "steal",
            label: "Steal",
            iconName: "bolt.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["steal": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "block",
            label: "Block",
            iconName: "shield.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["block": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "foul",
            label: "Foul",
            iconName: "hand.raised.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["foul": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "turnover",
            label: "Turnover",
            iconName: "arrow.uturn.backward",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["turnover": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "opponentTwoPoint",
            label: "Opponent 2PT",
            iconName: "xmark.seal.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: [:],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "opponentThreePoint",
            label: "Opponent 3PT",
            iconName: "xmark.seal.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: [:],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "opponentFreeThrow",
            label: "Opponent FT",
            iconName: "xmark.seal.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: [:],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .basketball)

    let scoringRules = ScoringRules(
        scoreLabel: "Points",
        primaryStatID: "points",
        teamEventPoints: [
            "twoPointMade": 2,
            "threePointMade": 3,
            "freeThrowMade": 1
        ],
        opponentEventPoints: [
            "opponentTwoPoint": 2,
            "opponentThreePoint": 3,
            "opponentFreeThrow": 1
        ]
    )
}

private let _basketballSportRegistration = SportCatalog.register(BasketballSport())
