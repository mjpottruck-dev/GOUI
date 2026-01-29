import Foundation
import Observation

@Observable
final class TeamStore {

    // MARK: - State
    var teams: [Team] = [] {
        didSet { save() }
    }

    var seasons: [Season] = [] {
        didSet { save() }
    }

    var activeSeasonID: UUID? {
        didSet { save() }
    }

    // MARK: - Init
    init() {
        load()
        ensureDefaultSeason()
        seedDemoTeamIfNeeded()
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

    // MARK: - Seasons
    func addSeason(_ season: Season) {
        seasons.append(season)
        if activeSeasonID == nil {
            activeSeasonID = season.id
        }
    }

    func setActiveSeason(_ seasonID: UUID) {
        activeSeasonID = seasonID
    }

    func activeSeason() -> Season? {
        guard let id = activeSeasonID else { return nil }
        return seasons.first(where: { $0.id == id })
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
            let data = try encoder.encode(AppData(teams: teams, seasons: seasons, activeSeasonID: activeSeasonID))
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
                seasons = []
                activeSeasonID = nil
                return
            }

            let data = try Data(contentsOf: url)

            if let decoded = try? JSONDecoder().decode(AppData.self, from: data) {
                teams = decoded.teams
                seasons = decoded.seasons
                activeSeasonID = decoded.activeSeasonID
                migrateIfNeeded()
                return
            }

            if let decoded = try? JSONDecoder().decode([Team].self, from: data) {
                teams = decoded
                seasons = []
                activeSeasonID = nil
                migrateIfNeeded()
                save()
                return
            }

            if let legacy = try? JSONDecoder().decode([LegacyTeam].self, from: data) {
                teams = legacy.map { $0.toTeam() }
                seasons = []
                activeSeasonID = nil
                migrateIfNeeded()
                save()
                return
            }

            print("❌ TeamStore load failed: could not decode teams.json (current or legacy). Resetting.")
            teams = []
            seasons = []
            activeSeasonID = nil

        } catch {
            print("❌ TeamStore load failed:", error)
            teams = []
            seasons = []
            activeSeasonID = nil
        }
    }

    private func ensureDefaultSeason() {
        guard seasons.isEmpty else { return }
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let isFall = month >= 8
        let name = "\(isFall ? "Fall" : "Spring") \(year)"
        let startMonth = isFall ? 8 : 1
        let startDate = calendar.date(from: DateComponents(year: year, month: startMonth, day: 1)) ?? now
        let endMonth = isFall ? 12 : 6
        let endDate = calendar.date(from: DateComponents(year: year, month: endMonth, day: 28)) ?? now
        let season = Season(name: name, startDate: startDate, endDate: endDate)
        seasons = [season]
        activeSeasonID = season.id
    }

    private func seedDemoTeamIfNeeded() {
        guard teams.isEmpty else { return }

        let players: [Player] = [
            Player(name: "Mateo Reyes", number: 1, position: .gk),
            Player(name: "Liam Foster", number: 2, position: .rb),
            Player(name: "Diego Navarro", number: 3, position: .cb),
            Player(name: "Noah Blake", number: 4, position: .cb),
            Player(name: "Ethan Park", number: 5, position: .lb),
            Player(name: "Marco Silva", number: 6, position: .cdm),
            Player(name: "Jonas Keller", number: 7, position: .cm),
            Player(name: "Aiden Brooks", number: 8, position: .cm),
            Player(name: "Rafael Costa", number: 9, position: .cam),
            Player(name: "Owen Hart", number: 10, position: .rm),
            Player(name: "Kai Novak", number: 11, position: .lm),
            Player(name: "Lucas Moretti", number: 12, position: .rw),
            Player(name: "Mason Reed", number: 13, position: .lw),
            Player(name: "Hugo Moreno", number: 14, position: .st),
            Player(name: "Santiago Ortiz", number: 15, position: .st),
            Player(name: "Felix Grant", number: 16, position: .rwb),
            Player(name: "Tariq Hussain", number: 17, position: .lwb),
            Player(name: "Nico Alvarez", number: 18, position: .cf)
        ]

        let starterIDs = Array(players.prefix(7)).map(\.id)
        let primaryGoalkeeperID = Team.primaryGoalkeeperID(from: players)
        let team = Team(
            name: "Demo Eleven",
            players: players,
            fieldSize: 7,
            startingOnFieldIDs: starterIDs,
            primaryFormation: .f433,
            primaryGoalkeeperID: primaryGoalkeeperID
        )

        teams = [team]
    }

    // MARK: - Migration
    private func migrateIfNeeded() {
        var changed = false

        for ti in teams.indices {
            if teams[ti].primaryGoalkeeperID == nil {
                let resolved = Team.primaryGoalkeeperID(from: teams[ti].players)
                if resolved != nil {
                    teams[ti].primaryGoalkeeperID = resolved
                    changed = true
                }
            }
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

                if teams[ti].matches[mi].seasonID == nil {
                    teams[ti].matches[mi].seasonID = activeSeasonID
                    changed = true
                }
            }
        }

        if changed {
            save()
        }
    }
}

private struct AppData: Codable {
    var teams: [Team]
    var seasons: [Season]
    var activeSeasonID: UUID?
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
            primaryFormation: .f433,
            primaryGoalkeeperID: Team.primaryGoalkeeperID(from: players),
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
            seasonID: nil,
            playerSeconds: playerSeconds ?? [:],
            playerStats: playerStats ?? [:]
        )
    }
}
