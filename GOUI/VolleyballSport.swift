import Foundation

struct VolleyballSport: SportDefinition {
    let id = SportCatalog.volleyballID
    let displayName = "Volleyball"
    let season: SportSeason = .fall
    let supportsTimer = false
    let supportsGoalie = false
    let supportsPositions = false
    let supportsCourtOverlay = false
    let supportsTeamScore = true
    let supportsPeriods = true
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .teamVsTeam

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "Set 1", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 2", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 3", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 4", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 5", duration: 0, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "setsWon", displayName: "Sets Won", shortLabel: "SW", countsForTeam: true, countsForPlayer: false),
        StatType(id: "kills", displayName: "Kills", shortLabel: "K", countsForTeam: true, countsForPlayer: true),
        StatType(id: "assists", displayName: "Assists", shortLabel: "A", countsForTeam: true, countsForPlayer: true),
        StatType(id: "aces", displayName: "Aces", shortLabel: "ACE", countsForTeam: true, countsForPlayer: true),
        StatType(id: "blocks", displayName: "Blocks", shortLabel: "BLK", countsForTeam: true, countsForPlayer: true),
        StatType(id: "digs", displayName: "Digs", shortLabel: "DIG", countsForTeam: true, countsForPlayer: true),
        StatType(id: "serveErrors", displayName: "Serve Errors", shortLabel: "SE", countsForTeam: true, countsForPlayer: true),
        StatType(id: "hittingErrors", displayName: "Hitting Errors", shortLabel: "HE", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "pointWon",
            label: "Point Won",
            iconName: "plus.circle.fill",
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
            id: "pointLost",
            label: "Point Lost",
            iconName: "minus.circle.fill",
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
            id: "setWon",
            label: "Set Won",
            iconName: "checkmark.seal.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["setsWon": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "setLost",
            label: "Set Lost",
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
            id: "kill",
            label: "Kill",
            iconName: "bolt.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["kills": 1],
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
            primaryStatChanges: ["assists": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "ace",
            label: "Ace",
            iconName: "sparkles",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["aces": 1],
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
            primaryStatChanges: ["blocks": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "dig",
            label: "Dig",
            iconName: "hand.raised.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["digs": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "serveError",
            label: "Serve Error",
            iconName: "exclamationmark.triangle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["serveErrors": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "hittingError",
            label: "Hitting Error",
            iconName: "exclamationmark.octagon.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["hittingErrors": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Sets",
        primaryStatID: "setsWon",
        teamEventPoints: [
            "setWon": 1
        ],
        opponentEventPoints: [
            "setLost": 1
        ],
        periodEventPoints: [
            "pointWon": 1,
            "kill": 1,
            "ace": 1,
            "block": 1
        ],
        opponentPeriodEventPoints: [
            "pointLost": 1,
            "serveError": 1,
            "hittingError": 1
        ]
    )
}

private let _volleyballSportRegistration = SportCatalog.register(VolleyballSport())
