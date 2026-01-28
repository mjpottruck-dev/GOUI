import Foundation
import Observation

@Observable
final class TeamStore {

    // MARK: - State
    var teams: [Team] = [] {
        didSet { save() }
    }

    // MARK: - Init
    init() {
        load()
    }

    // MARK: - CRUD (Teams)
    func addTeam(_ team: Team) {
        teams.append(team)
    }

    func deleteTeam(_ team: Team) {
        teams.removeAll { $0.id == team.id }
    }

    func updateTeam(_ team: Team) {
        if let idx = teams.firstIndex(where: { $0.id == team.id }) {
            teams[idx] = team
        }
    }

    // MARK: - Matches (Archive)
    func addMatchRecord(teamID: UUID, record: MatchRecord) {
        guard let idx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        teams[idx].matches.insert(record, at: 0)
    }

    func deleteMatch(teamID: UUID, matchID: UUID) {
        guard let idx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        teams[idx].matches.removeAll { $0.id == matchID }
    }

    func updateMatch(teamID: UUID, match: MatchRecord) {
        guard let teamIdx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        guard let matchIdx = teams[teamIdx].matches.firstIndex(where: { $0.id == match.id }) else { return }
        teams[teamIdx].matches[matchIdx] = match
    }

    // MARK: - Persistence
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("teams.json")
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(teams)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("❌ TeamStore save failed:", error)
        }
    }

    private func load() {
        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                teams = []
                return
            }

            let data = try Data(contentsOf: url)

            // 1) Try current decode first
            if let decoded = try? JSONDecoder().decode([Team].self, from: data) {
                teams = decoded
                migrateIfNeeded()
                return
            }

            // 2) Fallback: legacy decode (tolerant of shape changes)
            if let legacy = try? JSONDecoder().decode([LegacyTeam].self, from: data) {
                teams = legacy.map { $0.toTeam() }
                migrateIfNeeded()
                save() // write back in new format
                return
            }

            // If both fail, wipe (last resort)
            print("❌ TeamStore load failed: could not decode teams.json (current or legacy). Resetting.")
            teams = []

        } catch {
            print("❌ TeamStore load failed:", error)
            teams = []
        }
    }

    // MARK: - Migration
    private func migrateIfNeeded() {
        var changed = false

        for ti in teams.indices {
            for mi in teams[ti].matches.indices {
                let secondsKeys = Set(teams[ti].matches[mi].playerSeconds.keys)
                let statsKeys = Set(teams[ti].matches[mi].playerStats.keys)

                if !secondsKeys.isEmpty && statsKeys.isEmpty {
                    var newStats: [UUID: PlayerStatLine] = [:]
                    for pid in secondsKeys {
                        newStats[pid] = PlayerStatLine()
                    }
                    teams[ti].matches[mi].playerStats = newStats
                    changed = true
                } else if !secondsKeys.isEmpty && !secondsKeys.isSubset(of: statsKeys) {
                    for pid in secondsKeys.subtracting(statsKeys) {
                        teams[ti].matches[mi].playerStats[pid] = PlayerStatLine()
                        changed = true
                    }
                }
            }
        }

        if changed {
            save()
        }
    }
}

private struct LegacyTeam: Codable {
    var id: UUID
    var name: String
    var players: [Player]
    var fieldSize: Int
    var startingOnFieldIDs: [UUID]
    var matches: [LegacyMatchRecord]?

    func toTeam() -> Team {
        Team(
            id: id,
            name: name,
            players: players,
            fieldSize: fieldSize,
            startingOnFieldIDs: startingOnFieldIDs,
            matches: (matches ?? []).map { $0.toMatchRecord() }
        )
    }
}

private struct LegacyMatchRecord: Codable {
    var id: UUID?
    var date: Date?

    var opponent: String?
    var title: String?
    var notes: String?

    var goalsFor: Int?
    var goalsAgainst: Int?
    var secondsElapsed: Int?
    var fieldSize: Int?

    var playerSeconds: [UUID: Int]?
    var playerStats: [UUID: PlayerStatLine]?

    func toMatchRecord() -> MatchRecord {
        MatchRecord(
            id: id ?? UUID(),
            date: date ?? Date(),
            opponent: opponent ?? "",
            title: title ?? "",
            notes: notes ?? "",
            goalsFor: goalsFor ?? 0,
            goalsAgainst: goalsAgainst ?? 0,
            secondsElapsed: secondsElapsed ?? 0,
            fieldSize: fieldSize ?? 7,
            playerSeconds: playerSeconds ?? [:],
            playerStats: playerStats ?? [:]
        )
    }
}

