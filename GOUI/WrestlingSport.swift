import Foundation

struct WrestlingSport: SportDefinition {
    let id = SportCatalog.wrestlingID
    let displayName = "Wrestling"
    let season: SportSeason = .winter
    let supportsTimer = true
    let supportsGoalie = false
    let supportsPositions = false
    let supportsCourtOverlay = false
    let supportsTeamScore = true
    let supportsPeriods = true
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .dualIndividual

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "Period 1", duration: 2 * 60, maxCount: 1),
        PeriodDefinition(name: "Period 2", duration: 2 * 60, maxCount: 1),
        PeriodDefinition(name: "Period 3", duration: 2 * 60, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "matchPoints", displayName: "Match Points", shortLabel: "PTS", countsForTeam: true, countsForPlayer: true),
        StatType(id: "takedown", displayName: "Takedown", shortLabel: "TD", countsForTeam: true, countsForPlayer: true),
        StatType(id: "escape", displayName: "Escape", shortLabel: "ESC", countsForTeam: true, countsForPlayer: true),
        StatType(id: "reversal", displayName: "Reversal", shortLabel: "REV", countsForTeam: true, countsForPlayer: true),
        StatType(id: "nearFall", displayName: "Near Fall", shortLabel: "NF", countsForTeam: true, countsForPlayer: true),
        StatType(id: "penalty", displayName: "Penalty", shortLabel: "PEN", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pins", displayName: "Pins", shortLabel: "PIN", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "takedown",
            label: "Takedown",
            iconName: "figure.wrestling",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["takedown": 1, "matchPoints": 2],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "escape",
            label: "Escape",
            iconName: "arrow.up.right.circle",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["escape": 1, "matchPoints": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "reversal",
            label: "Reversal",
            iconName: "arrow.triangle.2.circlepath",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["reversal": 1, "matchPoints": 2],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "nearFall",
            label: "Near Fall",
            iconName: "bolt.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["nearFall": 1, "matchPoints": 2],
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
            uiAction: .direct,
            primaryStatChanges: ["penalty": 1, "matchPoints": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "pin",
            label: "Pin",
            iconName: "pin.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["pins": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        )
    ]

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Points",
        primaryStatID: "matchPoints",
        teamEventPoints: [
            "takedown": 2,
            "escape": 1,
            "reversal": 2,
            "nearFall": 2,
            "penalty": 1,
            "pin": 6
        ],
        opponentEventPoints: [:],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _wrestlingSportRegistration = SportCatalog.register(WrestlingSport())
