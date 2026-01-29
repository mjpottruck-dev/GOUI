import Foundation

struct SoccerSport: SportDefinition {
    let id = "soccer"
    let displayName = "Soccer"
    let season: SportSeason = .fall
    let supportsTimer = true
    let supportsGoalie = true
    let supportsPositions = true
    let supportsCourtOverlay = true
    let supportsTeamScore = true
    let supportsPeriods = true
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .teamVsTeam

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "1st Half", duration: 45 * 60, maxCount: 1),
        PeriodDefinition(name: "2nd Half", duration: 45 * 60, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "goals", displayName: "Goals", shortLabel: "G", countsForTeam: true, countsForPlayer: true),
        StatType(id: "assists", displayName: "Assists", shortLabel: "A", countsForTeam: true, countsForPlayer: true),
        StatType(id: "shots", displayName: "Shots", shortLabel: "S", countsForTeam: true, countsForPlayer: true),
        StatType(id: "shotsOnTarget", displayName: "Shots on Target", shortLabel: "SOT", countsForTeam: true, countsForPlayer: true),
        StatType(id: "yellowCards", displayName: "Yellow Cards", shortLabel: "YC", countsForTeam: true, countsForPlayer: true),
        StatType(id: "redCards", displayName: "Red Cards", shortLabel: "RC", countsForTeam: true, countsForPlayer: true),
        StatType(id: "saves", displayName: "Saves", shortLabel: "SV", countsForTeam: true, countsForPlayer: true),
        StatType(id: "goalsConceded", displayName: "Goals Conceded", shortLabel: "GC", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pkFaced", displayName: "PK Faced", shortLabel: "PKF", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pkSaved", displayName: "PK Saved", shortLabel: "PKS", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pkConceded", displayName: "PK Conceded", shortLabel: "PKC", countsForTeam: true, countsForPlayer: true)
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
            primaryStatChanges: ["goals": 1, "shots": 1, "shotsOnTarget": 1],
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
            shotOutcomeStats: ShotOutcomeStats(onTarget: ["shotsOnTarget": 1], offTarget: [:]),
            cardStatChanges: [:]
        ),
        EventType(
            id: "ownGoal",
            label: "Own Goal",
            iconName: "exclamationmark.triangle.fill",
            requiresPlayer: true,
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
            id: "pkAttempt",
            label: "PK Attempt",
            iconName: "circle.dashed",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .shotPenalty,
            primaryStatChanges: ["shots": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: ShotOutcomeStats(onTarget: ["shotsOnTarget": 1], offTarget: [:]),
            cardStatChanges: [:]
        ),
        EventType(
            id: "card",
            label: "Card",
            iconName: "rectangle.on.rectangle",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .card,
            primaryStatChanges: [:],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [
                .yellow: ["yellowCards": 1],
                .red: ["redCards": 1]
            ]
        ),
        EventType(
            id: "pkMade",
            label: "PK Made",
            iconName: "circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["goals": 1, "shots": 1, "shotsOnTarget": 1],
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
            primaryStatChanges: ["goalsConceded": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "pkSave",
            label: "PK Saved",
            iconName: "shield.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: true,
            usesGoalie: true,
            uiAction: .direct,
            primaryStatChanges: ["pkSaved": 1, "pkFaced": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "pkConceded",
            label: "PK Conceded",
            iconName: "shield.slash.fill",
            requiresPlayer: false,
            secondaryPlayerOptional: false,
            isGoalieOnly: true,
            usesGoalie: true,
            uiAction: .direct,
            primaryStatChanges: ["pkConceded": 1, "pkFaced": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .soccer)

    let scoringRules = ScoringRules(
        scoreLabel: "Goals",
        primaryStatID: "goals",
        teamEventPoints: [
            "goal": 1,
            "pkMade": 1
        ],
        opponentEventPoints: [
            "ownGoal": 1,
            "conceded": 1,
            "pkConceded": 1
        ],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _soccerSportRegistration = SportCatalog.register(SoccerSport())
