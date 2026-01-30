import Foundation

extension MatchStore {

    func buildMatchRecord(
        opponent: String,
        title: String = "",
        notes: String = "",
        date: Date = Date(),
        location: String = "",
        meetEvents: [String] = [],
        seasonName: String = ""
    ) -> MatchRecord {
        var rec = MatchRecord()
        rec.id = currentMatchID
        rec.date = date
        rec.opponent = opponent
        rec.title = title
        rec.notes = notes
        rec.location = location
        rec.meetEvents = meetEvents
        rec.seasonName = seasonName

        rec.goalsFor = goalsFor
        rec.goalsAgainst = goalsAgainst
        rec.secondsElapsed = elapsedSeconds
        rec.fieldSize = fieldSize
        rec.seasonID = currentSeasonID
        rec.sportID = sport.id
        rec.templateID = activeTemplate?.id
        rec.templateName = activeTemplate?.name
        rec.periodScores = periodScores
        rec.playerHoleScores = playerHoleScores
        rec.playerHolePutts = playerHolePutts

        rec.playerSeconds = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.secondsPlayed) })

        var stats: [UUID: PlayerStatLine] = [:]
        for p in players {
            var line = PlayerStatLine()
            for stat in sport.statSchema where stat.countsForPlayer {
                line.setValue(p.statValue(for: stat.id), for: stat.id)
            }
            stats[p.id] = line
        }
        rec.playerStats = stats

        return rec
    }
}
