import Foundation

struct WaterPoloSport: SportDefinition {
    let id = "water_polo"
    let displayName = "Water Polo"
    let season: SportSeason = .spring
    let supportsTimer = true
    let supportsGoalie = true
    let supportsPositions = false
    let supportsCourtOverlay = true
    let supportsTeamScore = true
    let supportsPeriods = true
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .teamVsTeam

    let periods: [PeriodDefinition] = [
        PeriodDefinition(name: "Q1", duration: 8 * 60, maxCount: 1),
        PeriodDefinition(name: "Q2", duration: 8 * 60, maxCount: 1),
        PeriodDefinition(name: "Q3", duration: 8 * 60, maxCount: 1),
        PeriodDefinition(name: "Q4", duration: 8 * 60, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "goals", displayName: "Goals", shortLabel: "G", countsForTeam: true, countsForPlayer: true),
        StatType(id: "assists", displayName: "Assists", shortLabel: "A", countsForTeam: true, countsForPlayer: true),
        StatType(id: "exclusions", displayName: "Exclusions", shortLabel: "EX", countsForTeam: true, countsForPlayer: true),
        StatType(id: "saves", displayName: "Saves", shortLabel: "SV", countsForTeam: true, countsForPlayer: true),
        StatType(id: "steals", displayName: "Steals", shortLabel: "STL", countsForTeam: true, countsForPlayer: true),
        StatType(id: "blocks", displayName: "Blocks", shortLabel: "BLK", countsForTeam: true, countsForPlayer: true),
        StatType(id: "turnovers", displayName: "Turnovers", shortLabel: "TO", countsForTeam: true, countsForPlayer: true)
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
            primaryStatChanges: ["goals": 1],
            secondaryStatChanges: ["assists": 1],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "exclusion",
            label: "Exclusion",
            iconName: "hand.raised.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["exclusions": 1],
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
            primaryStatChanges: ["steals": 1],
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
            id: "turnover",
            label: "Turnover",
            iconName: "arrow.uturn.backward",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["turnovers": 1],
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
            id: "opponentGoal",
            label: "Opponent Goal",
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

    let courtLayout = CourtLayoutDefinition(kind: .waterPolo)

    let scoringRules = ScoringRules(
        scoreLabel: "Goals",
        primaryStatID: "goals",
        teamEventPoints: ["goal": 1],
        opponentEventPoints: ["opponentGoal": 1],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _waterPoloSportRegistration = SportCatalog.register(WaterPoloSport())
