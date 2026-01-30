import Foundation

struct AnalyticsContext {
    let team: Team
    let sport: any SportDefinition
    let matches: [MatchRecord]
    let seasons: [Season]
    let player: Player?
    let shotAttempts: [ShotAttempt]

    init(team: Team, sport: any SportDefinition, matches: [MatchRecord], seasons: [Season], player: Player? = nil, shotAttempts: [ShotAttempt] = []) {
        self.team = team
        self.sport = sport
        self.matches = matches
        self.seasons = seasons
        self.player = player
        self.shotAttempts = shotAttempts
    }
}

struct AnalyticsMetricResult: Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    let footnote: String?
}

protocol AnalyticsMetric {
    var id: String { get }
    var title: String { get }
    var description: String { get }
    func compute(context: AnalyticsContext) -> AnalyticsMetricResult
}

protocol AnalyticsMetricPlugin {
    var sportID: String? { get }
    func metrics() -> [AnalyticsMetric]
}

struct AnalyticsEngine {
    static let shared = AnalyticsEngine()

    private let plugins: [AnalyticsMetricPlugin] = [
        GenericAnalyticsPlugin(),
        BasketballAnalyticsPlugin()
    ]

    func metrics(for sportID: String) -> [AnalyticsMetric] {
        plugins.filter { plugin in
            guard let pluginSportID = plugin.sportID else { return true }
            return pluginSportID == sportID
        }.flatMap { $0.metrics() }
    }
}

// MARK: - Shot Charts

struct ShotAttempt: Identifiable, Hashable {
    enum Zone: String, CaseIterable {
        case rim = "Rim"
        case paint = "Paint"
        case midRange = "Mid"
        case cornerThree = "Corner 3"
        case aboveBreakThree = "Arc 3"
    }

    let id: UUID
    let zone: Zone
    let made: Bool

    init(id: UUID = UUID(), zone: Zone, made: Bool) {
        self.id = id
        self.zone = zone
        self.made = made
    }
}

// MARK: - Metrics

struct EfficiencyMetric: AnalyticsMetric {
    let id = "efficiency"
    let title = "Efficiency"
    let description = "Positive production minus mistakes."

    func compute(context: AnalyticsContext) -> AnalyticsMetricResult {
        let totals = AnalyticsTotals.from(context: context)
        let positive = totals.points + totals.assists + totals.rebounds + totals.steals + totals.blocks
        let negative = totals.turnovers + totals.fouls
        let efficiency = positive - negative

        return AnalyticsMetricResult(
            id: id,
            title: title,
            value: "\(efficiency)",
            detail: "Positives \(positive) − Mistakes \(negative)",
            footnote: "Based on tracked stats in this season."
        )
    }
}

struct PerMinuteMetric: AnalyticsMetric {
    let id = "perMinute"
    let title = "Per-Minute Production"
    let description = "Stat output per minute played."

    func compute(context: AnalyticsContext) -> AnalyticsMetricResult {
        let totals = AnalyticsTotals.from(context: context)
        let minutes = max(totals.minutesPlayed, 1)
        let ppm = Double(totals.points) / Double(minutes)
        let apm = Double(totals.assists) / Double(minutes)
        let rpm = Double(totals.rebounds) / Double(minutes)

        return AnalyticsMetricResult(
            id: id,
            title: title,
            value: String(format: "%.2f PTS/min", ppm),
            detail: String(format: "%.2f AST/min • %.2f REB/min", apm, rpm),
            footnote: "Minutes are summed from tracked on-field seconds."
        )
    }
}

struct UsageRateMetric: AnalyticsMetric {
    let id = "usageRate"
    let title = "Usage Rate"
    let description = "Share of team possessions used (basketball)."

    func compute(context: AnalyticsContext) -> AnalyticsMetricResult {
        let totals = AnalyticsTotals.from(context: context)
        let teamTotals = AnalyticsTotals.from(context: AnalyticsContext(
            team: context.team,
            sport: context.sport,
            matches: context.matches,
            seasons: context.seasons
        ))

        let playerMinutes = max(totals.minutesPlayed, 1)
        let teamMinutes = max(teamTotals.teamMinutes, 1)
        let playerPossessions = Double(totals.fieldGoalAttempts + totals.freeThrowAttempts) + Double(totals.turnovers)
        let teamPossessions = Double(teamTotals.fieldGoalAttempts + teamTotals.freeThrowAttempts) + Double(teamTotals.turnovers)

        let usage = (playerPossessions * Double(teamMinutes)) / max(Double(playerMinutes) * teamPossessions, 1)

        return AnalyticsMetricResult(
            id: id,
            title: title,
            value: String(format: "%.1f%%", usage * 100),
            detail: "Est. possessions used: \(Int(playerPossessions)) / team \(Int(teamPossessions))",
            footnote: "Uses made shots + turnovers when attempts are not logged."
        )
    }
}

struct ShotChartMetric: AnalyticsMetric {
    let id = "shotChart"
    let title = "Shot Chart"
    let description = "Distribution of shot attempts by zone."

    func compute(context: AnalyticsContext) -> AnalyticsMetricResult {
        let attempts = context.shotAttempts
        guard !attempts.isEmpty else {
            return AnalyticsMetricResult(
                id: id,
                title: title,
                value: "No shot data",
                detail: "Tag shots in highlights to populate zones.",
                footnote: nil
            )
        }

        let grouped = Dictionary(grouping: attempts, by: { $0.zone })
        let breakdown = ShotAttempt.Zone.allCases.compactMap { zone -> String? in
            guard let zoneAttempts = grouped[zone] else { return nil }
            let made = zoneAttempts.filter { $0.made }.count
            return "\(zone.rawValue): \(made)/\(zoneAttempts.count)"
        }

        return AnalyticsMetricResult(
            id: id,
            title: title,
            value: "\(attempts.count) attempts",
            detail: breakdown.joined(separator: " • "),
            footnote: "Zones are inferred from clip tags."
        )
    }
}

struct SeasonTrendMetric: AnalyticsMetric {
    let id = "seasonTrends"
    let title = "Season Trends"
    let description = "Performance by season."

    func compute(context: AnalyticsContext) -> AnalyticsMetricResult {
        let matchesBySeason = Dictionary(grouping: context.matches, by: { $0.seasonID })
        let sortedSeasons = context.seasons.sorted { $0.startDate < $1.startDate }
        let trendLines = sortedSeasons.compactMap { season -> String? in
            guard let matches = matchesBySeason[season.id], !matches.isEmpty else { return nil }
            let avgFor = Double(matches.reduce(0) { $0 + $1.goalsFor }) / Double(matches.count)
            let avgAgainst = Double(matches.reduce(0) { $0 + $1.goalsAgainst }) / Double(matches.count)
            return "\(season.name): \(String(format: "%.1f", avgFor)) for / \(String(format: "%.1f", avgAgainst)) against"
        }

        if trendLines.isEmpty {
            return AnalyticsMetricResult(
                id: id,
                title: title,
                value: "No season data",
                detail: "Track matches across seasons to view trends.",
                footnote: nil
            )
        }

        return AnalyticsMetricResult(
            id: id,
            title: title,
            value: "\(trendLines.count) seasons",
            detail: trendLines.joined(separator: " • "),
            footnote: "Based on recorded match scores."
        )
    }
}

struct OnOffSplitMetric: AnalyticsMetric {
    let id = "onOff"
    let title = "On/Off Split"
    let description = "Estimated team impact when player is on the field."

    func compute(context: AnalyticsContext) -> AnalyticsMetricResult {
        guard let player = context.player else {
            return AnalyticsMetricResult(
                id: id,
                title: title,
                value: "Select player",
                detail: "Choose a player to calculate on/off splits.",
                footnote: nil
            )
        }

        let matchSeconds = context.matches.reduce(0) { $0 + max($1.secondsElapsed, 0) }
        let playerSeconds = context.matches.reduce(0) { total, match in
            total + (match.playerSeconds[player.id] ?? 0)
        }

        let onShare = matchSeconds > 0 ? Double(playerSeconds) / Double(matchSeconds) : 0
        let totalFor = context.matches.reduce(0) { $0 + $1.goalsFor }
        let totalAgainst = context.matches.reduce(0) { $0 + $1.goalsAgainst }

        let onFor = Int(Double(totalFor) * onShare)
        let onAgainst = Int(Double(totalAgainst) * onShare)
        let offFor = totalFor - onFor
        let offAgainst = totalAgainst - onAgainst

        return AnalyticsMetricResult(
            id: id,
            title: title,
            value: "On: \(onFor)-\(onAgainst)",
            detail: "Off: \(offFor)-\(offAgainst)",
            footnote: "Estimated from player time on field."
        )
    }
}

// MARK: - Plugins

struct GenericAnalyticsPlugin: AnalyticsMetricPlugin {
    let sportID: String? = nil

    func metrics() -> [AnalyticsMetric] {
        [
            EfficiencyMetric(),
            PerMinuteMetric(),
            ShotChartMetric(),
            SeasonTrendMetric(),
            OnOffSplitMetric()
        ]
    }
}

struct BasketballAnalyticsPlugin: AnalyticsMetricPlugin {
    let sportID: String? = "basketball"

    func metrics() -> [AnalyticsMetric] {
        [UsageRateMetric()]
    }
}

// MARK: - Totals helper

private struct AnalyticsTotals {
    var points: Int = 0
    var assists: Int = 0
    var rebounds: Int = 0
    var steals: Int = 0
    var blocks: Int = 0
    var fouls: Int = 0
    var turnovers: Int = 0
    var minutesPlayed: Int = 0
    var teamMinutes: Int = 0
    var fieldGoalAttempts: Int = 0
    var freeThrowAttempts: Int = 0

    static func from(context: AnalyticsContext) -> AnalyticsTotals {
        var totals = AnalyticsTotals()
        let statSchema = context.sport.statSchema
        let matchSeconds = context.matches.reduce(0) { $0 + max($1.secondsElapsed, 0) }
        totals.teamMinutes = max(matchSeconds / 60, 0)

        if let player = context.player {
            totals.minutesPlayed = context.matches.reduce(0) { total, match in
                let seconds = match.playerSeconds[player.id] ?? player.secondsPlayed
                return total + (seconds / 60)
            }
            let lines = context.matches.compactMap { $0.playerStats[player.id] }
            let aggregated = aggregate(lines: lines, statSchema: statSchema)
            totals.applyAggregated(aggregated)
        } else {
            totals.minutesPlayed = totals.teamMinutes
            let allLines = context.matches.flatMap { Array($0.playerStats.values) }
            let aggregated = aggregate(lines: allLines, statSchema: statSchema)
            totals.applyAggregated(aggregated)
        }

        return totals
    }

    mutating func applyAggregated(_ aggregated: [String: Int]) {
        points = aggregated["points"] ?? aggregated["goals"] ?? aggregated["score"] ?? 0
        assists = aggregated["assist"] ?? aggregated["assists"] ?? 0
        rebounds = aggregated["rebound"] ?? 0
        steals = aggregated["steal"] ?? 0
        blocks = aggregated["block"] ?? 0
        fouls = aggregated["foul"] ?? 0
        turnovers = aggregated["turnover"] ?? 0
        fieldGoalAttempts = (aggregated["twoPointMade"] ?? 0) + (aggregated["threePointMade"] ?? 0)
        freeThrowAttempts = aggregated["freeThrowMade"] ?? 0
    }

    static func aggregate(lines: [PlayerStatLine], statSchema: [StatType]) -> [String: Int] {
        var totals: [String: Int] = [:]
        let statIDs = statSchema.map { $0.id }
        for line in lines {
            for statID in statIDs {
                totals[statID, default: 0] += line.value(for: statID)
            }
        }
        return totals
    }
}
