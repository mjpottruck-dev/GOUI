import Foundation

extension MatchStore {

    func buildMatchRecord(opponent: String, title: String = "", notes: String = "", venue: String = "") -> MatchRecord {
        var rec = MatchRecord()
        rec.date = Date()
        rec.opponent = opponent
        rec.title = title
        rec.notes = notes
        rec.venue = venue

        rec.goalsFor = goalsFor
        rec.goalsAgainst = goalsAgainst
        rec.secondsElapsed = elapsedSeconds
        rec.fieldSize = fieldSize
        rec.seasonID = currentSeasonID
        rec.events = events

        rec.playerSeconds = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.secondsPlayed) })

        var stats: [UUID: PlayerStatLine] = [:]
        for p in players {
            var line = PlayerStatLine()
            line.goals = p.goals
            line.assists = p.assists
            line.shots = p.shots
            line.shotsOnTarget = p.shotsOnTarget
            line.yellowCards = p.yellowCards
            line.redCards = p.redCards
            line.saves = p.saves
            line.goalsConceded = p.goalsConceded
            line.pkFaced = p.pkFaced
            line.pkSaved = p.pkSaved
            line.pkConceded = p.pkConceded
            line.pkGoals = p.pkGoals
            line.pkAttempts = p.pkAttempts
            stats[p.id] = line
        }
        rec.playerStats = stats

        return rec
    }
}
