import Foundation
import Observation

@Observable
final class TeamStore {

    // MARK: - State
    var teams: [Team] = [] {
        didSet {
            save()
            if !isApplyingSync {
                scheduleSync()
            }
        }
    }

    var seasons: [Season] = [] {
        didSet { save() }
    }

    var activeSeasonID: UUID? {
        didSet { save() }
    }

    var deletedTeamIDs: [UUID] = [] {
        didSet { save() }
    }

    var deletedPlayerIDs: [UUID] = [] {
        didSet { save() }
    }

    var cloudSyncEnabled: Bool = UserDefaults.standard.bool(forKey: SettingsKeys.cloudSyncEnabled) {
        didSet {
            UserDefaults.standard.set(cloudSyncEnabled, forKey: SettingsKeys.cloudSyncEnabled)
            if cloudSyncEnabled {
                scheduleSync()
            }
        }
    }

    var syncStatus = SyncStatus()

    private lazy var syncManager: CloudSyncManager? = CloudSyncManager.makeIfAvailable()
    private var syncTask: Task<Void, Never>? = nil
    private var isApplyingSync = false

    // MARK: - Init
    init() {
        load()
        ensureDefaultSeason()
        seedDemoTeamIfNeeded()
        if cloudSyncEnabled {
            scheduleSync()
        }
    }

    // MARK: - CRUD (Teams)
    func addTeam(_ team: Team) {
        var newTeam = team
        let now = Date()
        newTeam.createdAt = now
        newTeam.updatedAt = now
        teams.append(newTeam)
    }

    func deleteTeam(_ team: Team) {
        deletedTeamIDs.append(team.id)
        teams.removeAll { $0.id == team.id }
    }

    func updateTeam(_ team: Team) {
        if let idx = teams.firstIndex(where: { $0.id == team.id }) {
            var updated = team
            updated.updatedAt = Date()
            teams[idx] = updated
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
        teams[idx].updatedAt = Date()
    }

    func deleteMatch(teamID: UUID, matchID: UUID) {
        guard let idx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        teams[idx].matches.removeAll { $0.id == matchID }
        teams[idx].updatedAt = Date()
    }

    func updateMatch(teamID: UUID, match: MatchRecord) {
        guard let teamIdx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        guard let matchIdx = teams[teamIdx].matches.firstIndex(where: { $0.id == match.id }) else { return }
        teams[teamIdx].matches[matchIdx] = match
        teams[teamIdx].updatedAt = Date()
    }

    // MARK: - Players
    func addPlayer(_ player: Player, to teamID: UUID) {
        guard let idx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        var newPlayer = player
        let now = Date()
        newPlayer.createdAt = now
        newPlayer.updatedAt = now
        teams[idx].players.append(newPlayer)
        teams[idx].updatedAt = now
    }

    func updatePlayer(_ player: Player, on teamID: UUID) {
        guard let idx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        guard let playerIndex = teams[idx].players.firstIndex(where: { $0.id == player.id }) else { return }
        var updated = player
        updated.updatedAt = Date()
        teams[idx].players[playerIndex] = updated
        teams[idx].updatedAt = Date()
    }

    func deletePlayer(_ player: Player, from teamID: UUID) {
        guard let idx = teams.firstIndex(where: { $0.id == teamID }) else { return }
        deletedPlayerIDs.append(player.id)
        teams[idx].players.removeAll { $0.id == player.id }
        teams[idx].updatedAt = Date()
    }

    // MARK: - Persistence
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("teams.json")
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(
                AppData(
                    teams: teams,
                    seasons: seasons,
                    activeSeasonID: activeSeasonID,
                    deletedTeamIDs: deletedTeamIDs,
                    deletedPlayerIDs: deletedPlayerIDs
                )
            )
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
                deletedTeamIDs = decoded.deletedTeamIDs
                deletedPlayerIDs = decoded.deletedPlayerIDs
                migrateIfNeeded()
                return
            }

            if let decoded = try? JSONDecoder().decode([Team].self, from: data) {
                teams = decoded
                seasons = []
                activeSeasonID = nil
                deletedTeamIDs = []
                deletedPlayerIDs = []
                migrateIfNeeded()
                save()
                return
            }

            if let legacy = try? JSONDecoder().decode([LegacyTeam].self, from: data) {
                teams = legacy.map { $0.toTeam() }
                seasons = []
                activeSeasonID = nil
                deletedTeamIDs = []
                deletedPlayerIDs = []
                migrateIfNeeded()
                save()
                return
            }

            print("❌ TeamStore load failed: could not decode teams.json (current or legacy). Resetting.")
            teams = []
            seasons = []
            activeSeasonID = nil
            deletedTeamIDs = []
            deletedPlayerIDs = []

        } catch {
            print("❌ TeamStore load failed:", error)
            teams = []
            seasons = []
            activeSeasonID = nil
            deletedTeamIDs = []
            deletedPlayerIDs = []
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
        let goalkeeperDepth = Team.goalkeeperDepthIDs(from: players)
        let team = Team(
            name: "Demo Eleven",
            players: players,
            fieldSize: 7,
            startingOnFieldIDs: starterIDs,
            primaryFormation: .f433,
            primaryGoalkeeperID: goalkeeperDepth.primary,
            secondaryGoalkeeperID: goalkeeperDepth.secondary,
            thirdGoalkeeperID: goalkeeperDepth.third
        )

        teams = [team]
    }

    // MARK: - Migration
    private func migrateIfNeeded() {
        var changed = false
        let now = Date()

        for ti in teams.indices {
            if teams[ti].createdAt > now {
                teams[ti].createdAt = now
                changed = true
            }
            if teams[ti].updatedAt > now {
                teams[ti].updatedAt = now
                changed = true
            }
            let resolvedDepth = Team.goalkeeperDepthIDs(
                from: teams[ti].players,
                currentPrimary: teams[ti].primaryGoalkeeperID,
                currentSecondary: teams[ti].secondaryGoalkeeperID,
                currentThird: teams[ti].thirdGoalkeeperID
            )
            if teams[ti].primaryGoalkeeperID != resolvedDepth.primary
                || teams[ti].secondaryGoalkeeperID != resolvedDepth.secondary
                || teams[ti].thirdGoalkeeperID != resolvedDepth.third {
                teams[ti].primaryGoalkeeperID = resolvedDepth.primary
                teams[ti].secondaryGoalkeeperID = resolvedDepth.secondary
                teams[ti].thirdGoalkeeperID = resolvedDepth.third
                changed = true
            }

            if teams[ti].primaryGoalkeeperID == nil
                && teams[ti].secondaryGoalkeeperID == nil
                && teams[ti].thirdGoalkeeperID == nil {
                let resolved = Team.primaryGoalkeeperID(from: teams[ti].players)
                if resolved != nil {
                    teams[ti].primaryGoalkeeperID = resolved
                    changed = true
                }
            }
            if teams[ti].sportID.isEmpty {
                teams[ti].sportID = SportCatalog.defaultSportID
                changed = true
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
                if teams[ti].matches[mi].sportID.isEmpty {
                    teams[ti].matches[mi].sportID = teams[ti].sportID
                    changed = true
                }
                for pid in teams[ti].matches[mi].playerStats.keys {
                    var line = teams[ti].matches[mi].playerStats[pid] ?? PlayerStatLine()
                    if line.statValues.isEmpty {
                        line.syncLegacyStatsFromDictionary()
                        if line.statValues.isEmpty {
                            line.statValues = [
                                "goals": line.goals,
                                "assists": line.assists,
                                "shots": line.shots,
                                "shotsOnTarget": line.shotsOnTarget,
                                "yellowCards": line.yellowCards,
                                "redCards": line.redCards,
                                "saves": line.saves,
                                "goalsConceded": line.goalsConceded,
                                "pkFaced": line.pkFaced,
                                "pkSaved": line.pkSaved,
                                "pkConceded": line.pkConceded
                            ]
                        }
                        teams[ti].matches[mi].playerStats[pid] = line
                        changed = true
                    }
                }
            }

            for pi in teams[ti].players.indices {
                if teams[ti].players[pi].createdAt > now {
                    teams[ti].players[pi].createdAt = now
                    changed = true
                }
                if teams[ti].players[pi].updatedAt > now {
                    teams[ti].players[pi].updatedAt = now
                    changed = true
                }
                if teams[ti].players[pi].positionName == nil {
                    teams[ti].players[pi].positionName = teams[ti].players[pi].position.rawValue
                    changed = true
                }
                if teams[ti].players[pi].statValues.isEmpty {
                    teams[ti].players[pi].statValues = [
                        "goals": teams[ti].players[pi].goals,
                        "assists": teams[ti].players[pi].assists,
                        "shots": teams[ti].players[pi].shots,
                        "shotsOnTarget": teams[ti].players[pi].shotsOnTarget,
                        "yellowCards": teams[ti].players[pi].yellowCards,
                        "redCards": teams[ti].players[pi].redCards,
                        "saves": teams[ti].players[pi].saves,
                        "goalsConceded": teams[ti].players[pi].goalsConceded,
                        "pkFaced": teams[ti].players[pi].pkFaced,
                        "pkSaved": teams[ti].players[pi].pkSaved,
                        "pkConceded": teams[ti].players[pi].pkConceded
                    ]
                    changed = true
                }
            }
        }

        if changed {
            save()
        }
    }

    private func scheduleSync() {
        guard cloudSyncEnabled else { return }
        guard syncManager != nil else { return }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            await self?.performSync()
        }
    }

    @MainActor
    private func performSync() async {
        guard cloudSyncEnabled else { return }
        guard let syncManager else { return }
        if syncStatus.isSyncing { return }
        syncStatus.isSyncing = true
        syncStatus.lastError = nil

        let matchesByTeam = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0.matches) })
        let payload = SyncPayload(
            teams: teams,
            deletedTeamIDs: deletedTeamIDs,
            deletedPlayerIDs: deletedPlayerIDs
        )

        do {
            let result = try await syncManager.sync(payload: payload, localMatches: matchesByTeam)
            isApplyingSync = true
            teams = result.teams
            deletedTeamIDs = result.deletedTeamIDs
            deletedPlayerIDs = result.deletedPlayerIDs
            isApplyingSync = false
            syncStatus.lastSyncDate = result.lastSyncDate
        } catch {
            syncStatus.lastError = error.localizedDescription
            print("❌ Cloud sync failed:", error)
        }

        syncStatus.isSyncing = false
    }
}

private struct AppData: Codable {
    var teams: [Team]
    var seasons: [Season]
    var activeSeasonID: UUID?
    var deletedTeamIDs: [UUID] = []
    var deletedPlayerIDs: [UUID] = []
}

private struct LegacyTeam: Codable {
    var id: UUID
    var name: String
    var players: [Player]
    var fieldSize: Int
    var startingOnFieldIDs: [UUID]
    var matches: [LegacyMatchRecord]?

    func toTeam() -> Team {
        let goalkeeperDepth = Team.goalkeeperDepthIDs(from: players)
        return Team(
            id: id,
            name: name,
            players: players,
            fieldSize: fieldSize,
            startingOnFieldIDs: startingOnFieldIDs,
            primaryFormation: .f433,
            primaryGoalkeeperID: goalkeeperDepth.primary,
            secondaryGoalkeeperID: goalkeeperDepth.secondary,
            thirdGoalkeeperID: goalkeeperDepth.third,
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
            sportID: SportCatalog.defaultSportID,
            playerSeconds: playerSeconds ?? [:],
            playerStats: playerStats ?? [:]
        )
    }
}
