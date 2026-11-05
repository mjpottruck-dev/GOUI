import CloudKit
import Foundation

struct SyncStatus: Equatable {
    var lastSyncDate: Date? = nil
    var isSyncing: Bool = false
    var lastError: String? = nil
}

struct SyncPayload {
    var teams: [Team]
    var deletedTeamIDs: [UUID]
    var deletedPlayerIDs: [UUID]
}

struct SyncResult {
    var teams: [Team]
    var deletedTeamIDs: [UUID]
    var deletedPlayerIDs: [UUID]
    var lastSyncDate: Date
}

/// Syncs each team, as one whole document, to the user's private iCloud database.
///
/// Each team (players, lineup, formation, goalkeepers, settings and every saved
/// match) is stored as one `TeamDoc` record holding the team's JSON as a CKAsset.
/// The earlier version synced only team names and player basics as separate records,
/// so a new phone or reinstall lost all match history, and a newer cloud copy reset
/// formation, field size, lineup and goalkeeper order.
///
/// Merging never throws work away:
/// - Matches and players are combined by ID from both copies, so two phones that each
///   recorded games keep all of them. Settings (name, formation, lineup) come from the
///   copy edited most recently; for a player on both, the more recently edited wins.
/// - Deleted matches and players are remembered on the team (`deletedMatchIDs`,
///   `deletedPlayerIDs`), and a deleted team is kept in iCloud as a tombstone record
///   (`deleted = 1`), so nothing deleted on one phone comes back from another.
///
/// CloudKit Dashboard setup (one time): the `TeamDoc` record type is created in the
/// Development environment on the first save. Add a QUERYABLE index on `recordName`
/// for `TeamDoc`, then deploy the schema to Production before release.
final class CloudSyncManager {
    enum CloudSyncError: LocalizedError {
        case unavailable(String)
        case missingIndex

        var errorDescription: String? {
            switch self {
            case .unavailable(let reason):
                return "CloudKit unavailable: \(reason)"
            case .missingIndex:
                return "iCloud setup incomplete: add a Queryable index on recordName for TeamDoc in the CloudKit Dashboard."
            }
        }
    }

    private static let recordType = "TeamDoc"
    private static let recordPrefix = "teamdoc-"

    private let container: CKContainer
    private let database: CKDatabase

    init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.database = container.privateCloudDatabase
    }

    private struct RemoteState {
        var teams: [UUID: Team] = [:]
        var tombstones: Set<UUID> = []
        /// Teams whose cloud copy exists but couldn't be fully read. Never uploaded
        /// over, so matches recorded elsewhere aren't lost from iCloud.
        var unreadable: Set<UUID> = []
    }

    /// `localMatches` is kept for the existing call site; matches now travel inside each team.
    func sync(payload: SyncPayload, localMatches: [UUID: [MatchRecord]]) async throws -> SyncResult {
        try await ensureCloudKitAvailable()

        let locallyDeleted = Set(payload.deletedTeamIDs)
        let remote = try await fetchRemote()

        var merged: [Team] = []
        var toUpload: [Team] = []
        var seen = Set<UUID>()

        // Local order first, so the coach's team order never changes.
        for local in payload.teams {
            guard seen.insert(local.id).inserted else { continue }
            if locallyDeleted.contains(local.id) || remote.tombstones.contains(local.id) { continue }
            if let theirs = remote.teams[local.id] {
                let combined = Self.merge(local, theirs)
                merged.append(combined)
                if combined != theirs && !remote.unreadable.contains(local.id) { toUpload.append(combined) }
            } else if remote.unreadable.contains(local.id) {
                merged.append(local) // cloud copy exists but couldn't be read: don't overwrite it
            } else {
                merged.append(local)
                // The untouched sample team stays on this phone only.
                if !(local.isDemo && local.matches.isEmpty) { toUpload.append(local) }
            }
        }
        // Then teams that only exist in iCloud (e.g. a new phone).
        for (id, theirs) in remote.teams.sorted(by: { $0.value.name < $1.value.name })
        where !seen.contains(id) && !locallyDeleted.contains(id) {
            merged.append(theirs)
        }

        defer { cleanUpTempFiles(for: toUpload) }
        var records = try toUpload.map(makeRecord)
        // Deleted teams become tombstones rather than vanishing, so other phones
        // learn about the deletion instead of re-uploading the team.
        records += payload.deletedTeamIDs.map(makeTombstone)
        if !records.isEmpty {
            try await save(records: records)
        }

        return SyncResult(
            teams: merged,
            deletedTeamIDs: [],
            deletedPlayerIDs: [],
            lastSyncDate: Date()
        )
    }

    // MARK: - Merge

    /// Combines two copies of the same team without losing matches or players.
    static func merge(_ a: Team, _ b: Team) -> Team {
        // The more recently edited copy supplies the team's own settings.
        let newer = b.updatedAt > a.updatedAt ? b : a
        let older = b.updatedAt > a.updatedAt ? a : b
        var result = newer

        let deletedMatches = Set(a.deletedMatchIDs).union(b.deletedMatchIDs)
        let deletedPlayers = Set(a.deletedPlayerIDs).union(b.deletedPlayerIDs)
        // Sorted so the same merge always produces an identical team (no needless uploads).
        result.deletedMatchIDs = deletedMatches.sorted { $0.uuidString < $1.uuidString }
        result.deletedPlayerIDs = deletedPlayers.sorted { $0.uuidString < $1.uuidString }

        // Players: union by ID; the more recently edited version of each wins.
        var players: [Player] = []
        var playerIndex: [UUID: Int] = [:]
        for p in newer.players + older.players where !deletedPlayers.contains(p.id) {
            if let i = playerIndex[p.id] {
                if p.updatedAt > players[i].updatedAt { players[i] = p }
            } else {
                playerIndex[p.id] = players.count
                players.append(p)
            }
        }
        result.players = players

        // Matches: union by ID, newest first.
        var matchByID: [UUID: MatchRecord] = [:]
        for m in older.matches + newer.matches where !deletedMatches.contains(m.id) {
            matchByID[m.id] = m // newer copy's version overwrites
        }
        result.matches = matchByID.values.sorted {
            $0.date != $1.date ? $0.date > $1.date : $0.id.uuidString < $1.id.uuidString
        }

        result.isDemo = a.isDemo && b.isDemo
        result.updatedAt = max(a.updatedAt, b.updatedAt)
        return result
    }

    // MARK: - CloudKit

    private func ensureCloudKitAvailable() async throws {
        let status = try await container.accountStatus()
        switch status {
        case .available:
            return
        case .noAccount:
            throw CloudSyncError.unavailable("No iCloud account is signed in")
        case .restricted:
            throw CloudSyncError.unavailable("The account is restricted")
        case .couldNotDetermine:
            throw CloudSyncError.unavailable("Could not determine account status")
        case .temporarilyUnavailable:
            throw CloudSyncError.unavailable("The iCloud account is temporarily unavailable")
        @unknown default:
            throw CloudSyncError.unavailable("Unknown CloudKit account status")
        }
    }

    /// Fetches every TeamDoc, following query cursors so large libraries aren't truncated.
    private func fetchRemote() async throws -> RemoteState {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        var state = RemoteState()
        do {
            let first = try await database.records(matching: query)
            absorb(first.matchResults, into: &state)
            var cursor = first.queryCursor
            while let next = cursor {
                let page = try await database.records(continuingMatchFrom: next)
                absorb(page.matchResults, into: &state)
                cursor = page.queryCursor
            }
        } catch let error as CKError where error.code == .unknownItem {
            // Record type doesn't exist yet (nothing has ever been uploaded). Carry on so
            // this sync uploads and creates it.
            return RemoteState()
        } catch let error as CKError where error.code == .invalidArguments {
            // Usually "recordName is not marked queryable". Don't upload blind: we'd
            // overwrite cloud copies we couldn't read.
            print("❌ CloudKit query failed:", error)
            throw CloudSyncError.missingIndex
        }
        return state
    }

    private func absorb(_ results: [(CKRecord.ID, Result<CKRecord, Error>)], into state: inout RemoteState) {
        for (recordID, result) in results {
            let name = recordID.recordName
            let teamID = UUID(uuidString: String(name.dropFirst(Self.recordPrefix.count)))
            guard case .success(let record) = result else {
                if let teamID { state.unreadable.insert(teamID) }
                continue
            }
            if (record["deleted"] as? Int64) == 1 {
                if let teamID { state.tombstones.insert(teamID) }
                continue
            }
            guard let asset = record["payload"] as? CKAsset,
                  let url = asset.fileURL,
                  let data = try? Data(contentsOf: url) else {
                if let teamID { state.unreadable.insert(teamID) }
                continue
            }
            do {
                let repairsBefore = DecodeRepairs.count
                let team = try JSONDecoder().decode(Team.self, from: data)
                if DecodeRepairs.count != repairsBefore {
                    // Partly readable: use what we can locally, but never upload over it.
                    state.unreadable.insert(team.id)
                }
                if let existing = state.teams[team.id] {
                    state.teams[team.id] = Self.merge(existing, team)
                } else {
                    state.teams[team.id] = team
                }
            } catch {
                print("⚠️ Skipping unreadable cloud team \(name):", error)
                if let teamID { state.unreadable.insert(teamID) }
            }
        }
        for id in state.tombstones { state.teams[id] = nil }
    }

    private func save(records: [CKRecord]) async throws {
        let (saveResults, _) = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )
        for (_, result) in saveResults {
            if case .failure(let error) = result { throw error }
        }
    }

    // MARK: - Records

    private static func recordID(_ teamID: UUID) -> CKRecord.ID {
        // Prefixed so it can't collide with records from the old "Team" schema,
        // which used the bare team UUID as the record name.
        CKRecord.ID(recordName: recordPrefix + teamID.uuidString)
    }

    private func tempURL(for team: Team) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("teamdoc-\(team.id.uuidString).json")
    }

    private func makeRecord(_ team: Team) throws -> CKRecord {
        let url = tempURL(for: team)
        try JSONEncoder().encode(team).write(to: url, options: [.atomic])

        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(team.id))
        record["name"] = team.name as CKRecordValue
        record["updatedAt"] = team.updatedAt as CKRecordValue
        record["payload"] = CKAsset(fileURL: url)
        return record
    }

    private func makeTombstone(_ teamID: UUID) -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(teamID))
        record["deleted"] = 1 as Int64 as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["payload"] = nil // drop the team's data from iCloud
        record["name"] = nil
        return record
    }

    private func cleanUpTempFiles(for teams: [Team]) {
        for team in teams {
            try? FileManager.default.removeItem(at: tempURL(for: team))
        }
    }
}
