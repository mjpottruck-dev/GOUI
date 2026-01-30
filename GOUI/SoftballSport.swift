import Foundation

struct SoftballSport: SportDefinition {
    let id = SportCatalog.softballID
    let displayName = "Softball"
    let season: SportSeason = .spring
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
        PeriodDefinition(name: "Inning 1", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Inning 2", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Inning 3", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Inning 4", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Inning 5", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Inning 6", duration: 0, maxCount: 1),
        PeriodDefinition(name: "Inning 7", duration: 0, maxCount: 1)
    ]

    let statSchema: [StatType] = [
        StatType(id: "ab", displayName: "AB", shortLabel: "AB", countsForTeam: true, countsForPlayer: true),
        StatType(id: "h", displayName: "Hits", shortLabel: "H", countsForTeam: true, countsForPlayer: true),
        StatType(id: "single", displayName: "1B", shortLabel: "1B", countsForTeam: true, countsForPlayer: true),
        StatType(id: "double", displayName: "2B", shortLabel: "2B", countsForTeam: true, countsForPlayer: true),
        StatType(id: "triple", displayName: "3B", shortLabel: "3B", countsForTeam: true, countsForPlayer: true),
        StatType(id: "hr", displayName: "HR", shortLabel: "HR", countsForTeam: true, countsForPlayer: true),
        StatType(id: "rbi", displayName: "RBI", shortLabel: "RBI", countsForTeam: true, countsForPlayer: true),
        StatType(id: "bb", displayName: "BB", shortLabel: "BB", countsForTeam: true, countsForPlayer: true),
        StatType(id: "k", displayName: "K", shortLabel: "K", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pitchIP", displayName: "IP", shortLabel: "IP", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pitchH", displayName: "Pitcher H", shortLabel: "PH", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pitchR", displayName: "Pitcher R", shortLabel: "PR", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pitchER", displayName: "Pitcher ER", shortLabel: "PER", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pitchBB", displayName: "Pitcher BB", shortLabel: "PBB", countsForTeam: true, countsForPlayer: true),
        StatType(id: "pitchK", displayName: "Pitcher K", shortLabel: "PK", countsForTeam: true, countsForPlayer: true),
        StatType(id: "errors", displayName: "Errors", shortLabel: "E", countsForTeam: true, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = [
        EventType(
            id: "single",
            label: "Single",
            iconName: "1.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["ab": 1, "h": 1, "single": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "double",
            label: "Double",
            iconName: "2.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["ab": 1, "h": 1, "double": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "triple",
            label: "Triple",
            iconName: "3.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["ab": 1, "h": 1, "triple": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "homeRun",
            label: "Home Run",
            iconName: "star.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["ab": 1, "h": 1, "hr": 1, "rbi": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "walk",
            label: "Walk",
            iconName: "figure.walk",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["bb": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "strikeout",
            label: "Strikeout",
            iconName: "xmark",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["ab": 1, "k": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "out",
            label: "Out",
            iconName: "circle",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["ab": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "error",
            label: "Error",
            iconName: "exclamationmark.triangle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["errors": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "rbi",
            label: "RBI",
            iconName: "plus.circle.fill",
            requiresPlayer: true,
            secondaryPlayerOptional: false,
            isGoalieOnly: false,
            usesGoalie: false,
            uiAction: .direct,
            primaryStatChanges: ["rbi": 1],
            secondaryStatChanges: [:],
            shotOutcomeStats: nil,
            cardStatChanges: [:]
        ),
        EventType(
            id: "run",
            label: "Run",
            iconName: "flag.checkered",
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

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Runs",
        primaryStatID: "rbi",
        teamEventPoints: [
            "run": 1,
            "homeRun": 1
        ],
        opponentEventPoints: [:],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _softballSportRegistration = SportCatalog.register(SoftballSport())
