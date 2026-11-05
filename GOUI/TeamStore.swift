import CryptoKit
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

    /// iCloud sync is off in App Store builds for v1. It works for one phone, but
    /// several multi-phone edge cases (simultaneous syncs, stale edit screens,
    /// production schema setup) are still open. Debug builds keep it for testing.
    #if DEBUG
    static let syncAvailable = true
    #else
    static let syncAvailable = false
    #endif

    var cloudSyncEnabled: Bool = TeamStore.syncAvailable && UserDefaults.standard.bool(forKey: SettingsKeys.cloudSyncEnabled) {
        didSet {
            UserDefaults.standard.set(cloudSyncEnabled, forKey: SettingsKeys.cloudSyncEnabled)
            if cloudSyncEnabled {
                scheduleSync()
            }
        }
    }

    var syncStatus = SyncStatus()

    private let syncManager = CloudSyncManager()

    /// Set when teams.json exists but couldn't be read (e.g. file protection before the
    /// phone's first unlock). While set, nothing is written or synced, so the real file
    /// is never overwritten with an empty or demo roster. Cleared on the next launch.
    private var dataLoadFailed = false
    private var syncTask: Task<Void, Never>? = nil
    private var isApplyingSync = false
    /// A change arrived while a sync was running; run one more sync when it finishes.
    private var needsResync = false

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
            // Record anything removed by this edit so an iCloud merge can't bring it back.
            let old = teams[idx]
            // Editors often build a fresh Team, which would erase sync bookkeeping.
            updated.deletedPlayerIDs = Array(Set(old.deletedPlayerIDs).union(updated.deletedPlayerIDs))
            updated.deletedMatchIDs = Array(Set(old.deletedMatchIDs).union(updated.deletedMatchIDs))
            updated.isDemo = old.isDemo && team.name == old.name // renaming makes it a real team
            let keptPlayers = Set(team.players.map(\.id))
            let keptMatches = Set(team.matches.map(\.id))
            for p in old.players where !keptPlayers.contains(p.id) && !updated.deletedPlayerIDs.contains(p.id) {
                updated.deletedPlayerIDs.append(p.id)
            }
            for m in old.matches where !keptMatches.contains(m.id) && !updated.deletedMatchIDs.contains(m.id) {
                updated.deletedMatchIDs.append(m.id)
            }
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
        if !teams[idx].deletedMatchIDs.contains(matchID) { teams[idx].deletedMatchIDs.append(matchID) }
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
        if !teams[idx].deletedPlayerIDs.contains(player.id) { teams[idx].deletedPlayerIDs.append(player.id) }
        teams[idx].updatedAt = Date()
    }

    // MARK: - Persistence
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("teams.json")
    }

    private func save() {
        guard !dataLoadFailed else { return }
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
            DecodeRepairs.count = 0

            if let decoded = try? JSONDecoder().decode(AppData.self, from: data) {
                if DecodeRepairs.count > 0 {
                    // Some items couldn't be read and were skipped or defaulted. Keep the
                    // original file before anything is saved over it.
                    print("⚠️ Repaired \(DecodeRepairs.count) unreadable value(s) in teams.json")
                    backupUnreadableDataFile(url)
                }
                teams = decoded.teams
                seasons = decoded.seasons
                activeSeasonID = decoded.activeSeasonID
                deletedTeamIDs = decoded.deletedTeamIDs
                deletedPlayerIDs = decoded.deletedPlayerIDs
                migrateIfNeeded()
                return
            }

            if let decoded = try? JSONDecoder().decode([Team].self, from: data) {
                backupUnreadableDataFile(url) // older format: keep the original too
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
                backupUnreadableDataFile(url) // older format: keep the original too
                teams = legacy.map { $0.toTeam() }
                seasons = []
                activeSeasonID = nil
                deletedTeamIDs = []
                deletedPlayerIDs = []
                migrateIfNeeded()
                save()
                return
            }

            print("❌ TeamStore load failed: could not decode teams.json (current or legacy). Backing up, then resetting.")
            backupUnreadableDataFile(url)
            teams = []
            seasons = []
            activeSeasonID = nil
            deletedTeamIDs = []
            deletedPlayerIDs = []

        } catch {
            // The file exists but couldn't be read: don't treat that as "no data".
            print("❌ TeamStore load failed:", error)
            dataLoadFailed = true
            backupUnreadableDataFile(fileURL)
            teams = []
            seasons = []
            activeSeasonID = nil
            deletedTeamIDs = []
            deletedPlayerIDs = []
        }
    }

    /// Copies an unreadable teams.json aside before the app starts fresh, so a bad
    /// update or a model change can never permanently erase a coach's teams and match
    /// history. The copy (teams.unreadable-<date>.json) stays in the app's Documents
    /// folder and can be recovered by a later build.
    private func backupUnreadableDataFile(_ url: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return }
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("teams.unreadable-\(stamp).json")
        do {
            try fm.copyItem(at: url, to: backup)
            print("⚠️ Saved unreadable data to", backup.lastPathComponent)
        } catch {
            print("❌ Could not back up unreadable teams.json:", error)
        }
    }

    /// A UUID derived from a string, identical on every device.
    static func stableID(for key: String) -> UUID {
        let digest = Insecure.MD5.hash(data: Data(key.utf8))
        var b = Array(digest)
        b[6] = (b[6] & 0x0F) | 0x30 // version 3 (name-based, MD5)
        b[8] = (b[8] & 0x3F) | 0x80 // RFC 4122 variant
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                           b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
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
        // Same name → same ID on every device, so synced matches stay in their season.
        let season = Season(id: Self.stableID(for: "season:" + name), name: name, startDate: startDate, endDate: endDate)
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

        let starterIDs = Array(players.prefix(11)).map(\.id)
        let goalkeeperDepth = Team.goalkeeperDepthIDs(from: players)
        let team = Team(
            name: "Demo Eleven",
            players: players,
            fieldSize: 11,
            startingOnFieldIDs: starterIDs,
            primaryFormation: .f433,
            primaryGoalkeeperID: goalkeeperDepth.primary,
            secondaryGoalkeeperID: goalkeeperDepth.secondary,
            thirdGoalkeeperID: goalkeeperDepth.third
        )

        var demo = team
        demo.isDemo = true
        teams = [demo]
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
            }
        }

        if changed {
            save()
        }
    }

    private func scheduleSync() {
        guard Self.syncAvailable, cloudSyncEnabled, !dataLoadFailed else { return }
        // Never cancel a sync that's already talking to iCloud; just run again after it.
        if syncStatus.isSyncing {
            needsResync = true
            return
        }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // debounce rapid edits
            } catch {
                return // superseded by a newer edit
            }
            await self?.performSync()
        }
    }

    @MainActor
    private func performSync() async {
        guard cloudSyncEnabled else { return }
        if syncStatus.isSyncing { needsResync = true; return }
        syncStatus.isSyncing = true
        needsResync = false
        syncStatus.lastError = nil

        let snapshot = teams
        let snapshotDeleted = Set(deletedTeamIDs)
        let matchesByTeam = Dictionary(teams.map { ($0.id, $0.matches) }, uniquingKeysWith: { a, _ in a })
        let payload = SyncPayload(
            teams: teams,
            deletedTeamIDs: deletedTeamIDs,
            deletedPlayerIDs: deletedPlayerIDs
        )

        do {
            let result = try await syncManager.sync(payload: payload, localMatches: matchesByTeam)

            // The coach may have saved a match or edited a team while the sync was
            // running. Keep those newer local versions instead of overwriting them.
            let before = Dictionary(snapshot.map { ($0.id, $0.updatedAt) }, uniquingKeysWith: { a, _ in a })
            let current = teams
            let currentByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let deletedNow = Set(deletedTeamIDs)
            var changedDuringSync = false
            var merged: [Team] = result.teams.compactMap { synced in
                if deletedNow.contains(synced.id) { return nil }
                if let local = currentByID[synced.id],
                   local.updatedAt > (before[synced.id] ?? .distantPast) {
                    changedDuringSync = true
                    return local
                }
                return synced
            }
            let mergedIDs = Set(merged.map(\.id))
            for team in current where before[team.id] == nil && !mergedIDs.contains(team.id) {
                merged.append(team) // created during the sync
                changedDuringSync = true
            }

            isApplyingSync = true
            teams = merged
            // Keep deletions made during the sync; the next sync sends them.
            deletedTeamIDs = deletedTeamIDs.filter { !snapshotDeleted.contains($0) }
            deletedPlayerIDs = result.deletedPlayerIDs
            isApplyingSync = false
            if changedDuringSync || !deletedTeamIDs.isEmpty {
                needsResync = true
            }
            syncStatus.lastSyncDate = result.lastSyncDate
        } catch {
            syncStatus.lastError = error.localizedDescription
            print("❌ Cloud sync failed:", error)
        }

        syncStatus.isSyncing = false
        if needsResync {
            needsResync = false
            scheduleSync()
        }
    }
}

private struct AppData: Codable {
    var teams: [Team]
    var seasons: [Season]
    var activeSeasonID: UUID?
    var deletedTeamIDs: [UUID] = []
    var deletedPlayerIDs: [UUID] = []
}

extension AppData {
    // Tolerant like the models in Models.swift: missing keys get defaults, and one
    // unreadable team or season is skipped instead of failing the whole file.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let teams: [Team] = c.lossyArray(.teams)
        let seasons: [Season] = c.lossyArray(.seasons)
        let activeSeasonID: UUID? = c.value(.activeSeasonID, or: nil)
        self.init(
            teams: teams,
            seasons: seasons,
            activeSeasonID: activeSeasonID,
            deletedTeamIDs: c.value(.deletedTeamIDs, or: []),
            deletedPlayerIDs: c.value(.deletedPlayerIDs, or: [])
        )
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
            playerSeconds: playerSeconds ?? [:],
            playerStats: playerStats ?? [:]
        )
    }
}
