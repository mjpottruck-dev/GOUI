import Foundation

extension MatchStore {

    func buildMatchRecord(opponent: String, title: String = "", notes: String = "") -> MatchRecord {
        var rec = MatchRecord()
        rec.date = Date()
        rec.opponent = opponent
        rec.title = title
        rec.notes = notes

        rec.goalsFor = goalsFor
        rec.goalsAgainst = goalsAgainst
        rec.secondsElapsed = elapsedSeconds
        rec.fieldSize = fieldSize
        rec.seasonID = currentSeasonID
        rec.sportID = sport.id

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
