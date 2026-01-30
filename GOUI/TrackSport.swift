import Foundation

struct TrackSport: SportDefinition {
    let id = SportCatalog.trackID
    let displayName = "Track & Field"
    let season: SportSeason = .spring
    let supportsTimer = false
    let supportsGoalie = false
    let supportsPositions = false
    let supportsCourtOverlay = false
    let supportsTeamScore = false
    let supportsPeriods = false
    let supportsHoles = false
    let defaultHoleCount = 0
    let scoringMode: ScoringMode = .individual

    let periods: [PeriodDefinition] = []

    let statSchema: [StatType] = [
        StatType(id: "timeSeconds", displayName: "Time (sec)", shortLabel: "TIME", countsForTeam: false, countsForPlayer: true),
        StatType(id: "distanceMeters", displayName: "Distance (m)", shortLabel: "DIST", countsForTeam: false, countsForPlayer: true),
        StatType(id: "place", displayName: "Place", shortLabel: "PLC", countsForTeam: false, countsForPlayer: true),
        StatType(id: "personalRecord", displayName: "PR", shortLabel: "PR", countsForTeam: false, countsForPlayer: true)
    ]

    let eventTypes: [EventType] = []

    let courtLayout = CourtLayoutDefinition(kind: .none)

    let scoringRules = ScoringRules(
        scoreLabel: "Points",
        primaryStatID: "place",
        teamEventPoints: [:],
        opponentEventPoints: [:],
        periodEventPoints: [:],
        opponentPeriodEventPoints: [:]
    )
}

private let _trackSportRegistration = SportCatalog.register(TrackSport())
