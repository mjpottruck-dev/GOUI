import Foundation

struct FootballSport: SportDefinition {
    let id = SportCatalog.footballID
    let displayName = "Football"
    let season: SportSeason = .fall
    let supportsTimer = true
    let supportsGoalie = false
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
        StatType(id: "passAtt", displayName: "Pass Attempts", shortLabel: "ATT", countsForTeam: true, countsForPlayer: true),
        StatType(id: "passComp", displayName: "Pass Completions", shortLabel: "COMP", countsForTeam: true, countsForPlayer: true),
        StatType(id: "passYds", displayName: "Pass Yards", shortLabel: "PY", countsForTeam: true, countsForPlayer: true),
        StatType(id: "passTD", displayName: "Pass TD", shortLabel: "PTD", countsForTeam: true, countsForPlayer: true),
        StatType(id: "passINT", displayName: "Pass INT", shortLabel: "INT", countsForTeam: true, countsForPlayer: true),
        StatType(id: "rushAtt", displayName: "Rush Attempts", shortLabel: "CAR", countsForTeam: true, countsForPlayer: true),
        StatType(id: "rushYds", displayName: "Rush Yards", shortLabel: "RY", countsForTeam: true, countsForPlayer: true),
        StatType(id: "receptions", displayName: "Receptions", shortLabel: "REC", countsForTeam: true, countsForPlayer: true),
        StatType(id: "recYds", displayName: "Rec Yards", shortLabel: "RECY", countsForTeam: true, countsForPlayer: true),
        StatType(id: "td", displayName: "TD", shortLabel: "TD", countsForTeam: true, countsForPlayer: true),
        StatType(id: "tackles", displayName: "Tackles", shortLabel: "TKL", countsForTeam: true, countsForPlayer: true),
        StatType(id: "sacks", displayName: "Sacks", shortLabel: "SCK", countsForTeam: true, countsForPlayer: true),
        StatType(id: "defInt", displayName: "Interceptions", shortLabel: "INT", countsForTeam: true, countsForPlayer: true),
        StatType(id: "forcedFumbles", displayName: "Forced Fumbles", shortLabel: "FF", countsForTeam: true, countsForPlayer: true),
        StatType(id: "fgMade", displayName: "FG Made", shortLabel: "FGM", countsForTeam: true, countsForPlayer: true),
        StatType(id: "fgAtt", displayName: "FG Att", shortLabel: "FGA", countsForTeam: true, countsForPlayer: true),
        StatType(id: "xpMade", displayName: "XP Made", shortLabel: "XPM", countsForTeam: true, countsForPlayer: true),
        StatType(id: "xpAtt", displayName: "XP Att", shortLabel: "XPA", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "passCompletion",
            label: "Pass Completion",
            iconName: "checkmark.seal.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: true,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .assist,
            primaryStatChanges: ["passAtt": 1, "passComp": 1],
            secondaryStatChanges: ["receptions": 1],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "passAttempt",
            label: "Pass Attempt",
            iconName: "arrow.up.right.circle",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["passAtt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "rushAttempt",
            label: "Rush Attempt",
            iconName: "figure.run",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["rushAtt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "touchdown",
            label: "TD",
            iconName: "star.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: true,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .assist,
            primaryStatChanges: ["td": 1],
            secondaryStatChanges: ["passTD": 1],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "interception",
            label: "INT",
            iconName: "arrow.triangle.2.circlepath",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["defInt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "sack",
            label: "Sack",
            iconName: "shield.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["sacks": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "tackle",
            label: "Tackle",
            iconName: "figure.wrestling",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["tackles": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "fgMade",
            label: "FG Made",
            iconName: "circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["fgMade": 1, "fgAtt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "fgMissed",
            label: "FG Missed",
            iconName: "circle",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["fgAtt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "xpMade",
            label: "XP Made",
            iconName: "plus.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["xpMade": 1, "xpAtt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "xpMissed",
            label: "XP Missed",
            iconName: "plus.circle",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["xpAtt": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Points",
        primaryStatID: "td",
        teamEventPoints: [
            "touchdown": 6,
            "fgMade": 3,
            "xpMade": 1
        ],
        opponentEventPoints: [:],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _footballSportRegistration = SportCatalog.register(FootballSport())
