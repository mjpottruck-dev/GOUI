import Foundation

struct LacrosseSport: SportDefinition {
    let id = SportCatalog.lacrosseID
    let displayName = "Lacrosse"
    let season: SportSeason = .spring
    let supportsTimer = true
    let supportsGoalie = true
    let supportsPositions = false
    let supportsCourtOverlay = false
    let supportsTeamScore = true
    let supportsPeriods = true
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .teamVsTeam

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "1st Quarter", duration: 12 * 60, maxCount: 1),
        PeriodDefinition(name: "2nd Quarter", duration: 12 * 60, maxCount: 1),
        PeriodDefinition(name: "3rd Quarter", duration: 12 * 60, maxCount: 1),
        PeriodDefinition(name: "4th Quarter", duration: 12 * 60, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "goals", displayName: "Goals", shortLabel: "G", countsForTeam: true, countsForPlayer: true),
        StatType(id: "assists", displayName: "Assists", shortLabel: "A", countsForTeam: true, countsForPlayer: true),
        StatType(id: "shots", displayName: "Shots", shortLabel: "S", countsForTeam: true, countsForPlayer: true),
        StatType(id: "groundBalls", displayName: "Ground Balls", shortLabel: "GB", countsForTeam: true, countsForPlayer: true),
        StatType(id: "saves", displayName: "Saves", shortLabel: "SV", countsForTeam: true, countsForPlayer: true),
        StatType(id: "penalties", displayName: "Penalties", shortLabel: "PEN", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "goal",
            label: "Goal",
            iconName: "checkmark.seal.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: true,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .assist,
            primaryStatChanges: ["goals": 1, "shots": 1],
            secondaryStatChanges: ["assists": 1],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "shot",
            label: "Shot",
            iconName: "scope",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .shot,
            primaryStatChanges: ["shots": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "assist",
            label: "Assist",
            iconName: "hand.thumbsup.fill",
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
            id: "groundBall",
            label: "Ground Ball",
            iconName: "circle.grid.cross",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["groundBalls": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "penalty",
            label: "Penalty",
            iconName: "exclamationmark.triangle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .card,
            primaryStatChanges: ["penalties": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "save",
            label: "Save",
            iconName: "hand.raised.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: true,
            usesGoalie: true,
            uiAction: .direct,
            primaryStatChanges: ["saves": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "conceded",
            label: "Conceded",
            iconName: "xmark.seal.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: true,
            usesGoalie: true,
            uiAction: .direct,
            primaryStatChanges: [:],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Goals",
        primaryStatID: "goals",
        teamEventPoints: [
            "goal": 1
        ],
        opponentEventPoints: [
            "conceded": 1
        ],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _lacrosseSportRegistration = SportCatalog.register(LacrosseSport())
