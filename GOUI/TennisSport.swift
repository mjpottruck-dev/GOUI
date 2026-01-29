import Foundation

struct TennisSport: SportDefinition {
    let id = SportCatalog.tennisID
    let displayName = "Tennis"
    let season: SportSeason = .spring
    let supportsTimer = false
    let supportsGoalie = false
    let supportsPositions = false
    let supportsCourtOverlay = false
    let supportsTeamScore = false
    let supportsPeriods = true
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .dualIndividual

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "Set 1", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 2", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 3", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 4", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Set 5", duration: 0, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "setsWon", displayName: "Sets Won", shortLabel: "SW", countsForTeam: true, countsForPlayer: true),
        StatType(id: "gamesWon", displayName: "Games Won", shortLabel: "GW", countsForTeam: true, countsForPlayer: true),
        StatType(id: "aces", displayName: "Aces", shortLabel: "ACE", countsForTeam: true, countsForPlayer: true),
        StatType(id: "doubleFaults", displayName: "Double Faults", shortLabel: "DF", countsForTeam: true, countsForPlayer: true),
        StatType(id: "winners", displayName: "Winners", shortLabel: "W", countsForTeam: true, countsForPlayer: true),
        StatType(id: "unforcedErrors", displayName: "Unforced Errors", shortLabel: "UE", countsForTeam: true, countsForPlayer: true),
        StatType(id: "firstServeIn", displayName: "First Serve In", shortLabel: "1st", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "gameWon",
            label: "Game Won",
            iconName: "plus.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["gamesWon": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "gameLost",
            label: "Game Lost",
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
            requiresPlayer: true,
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
            id: "doubleFault",
            label: "Double Fault",
            iconName: "exclamationmark.triangle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["doubleFaults": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "winner",
            label: "Winner",
            iconName: "bolt.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["winners": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "unforcedError",
            label: "Unforced Error",
            iconName: "exclamationmark.octagon.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["unforcedErrors": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "firstServeIn",
            label: "1st Serve In",
            iconName: "checkmark.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["firstServeIn": 1],
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
            "gameWon": 1
        ],
        opponentPeriodEventPoints: [
            "gameLost": 1
        ]
    )
}

private let _tennisSportRegistration = SportCatalog.register(TennisSport())
