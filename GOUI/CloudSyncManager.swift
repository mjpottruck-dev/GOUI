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
/// Conflicts: per team, the copy with the newer `updatedAt` wins (last writer wins).
///
/// CloudKit Dashboard setup (one time): the `TeamDoc` record type is created
/// automatically in the Development environment on first save. To query it, add a
/// QUERYABLE index on `recordName` for `TeamDoc`, then deploy the schema to Production
/// before release.
final class CloudSyncManager {
    enum CloudSyncError: LocalizedError {
        case unavailable(String)

        var errorDescription: String? {
            switch self {
            case .unavailable(let reason):
                return "CloudKit unavailable: \(reason)"
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

    /// `localMatches` is kept for the existing call site; matches now travel inside each team.
    func sync(payload: SyncPayload, localMatches: [UUID: [MatchRecord]]) async throws -> SyncResult {
        try await ensureCloudKitAvailable()

        let deleted = Set(payload.deletedTeamIDs)

        // 1. Read what the cloud has.
        let remoteTeams = try await fetchRemoteTeams()
        let remoteByID = Dictionary(remoteTeams.map { ($0.id, $0) }, uniquingKeysWith: { a, b in
            a.updatedAt >= b.updatedAt ? a : b
        })
        let localByID = Dictionary(payload.teams.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        // 2. Merge: newer copy of each team wins; deleted teams are dropped.
        var merged: [Team] = []
        var toUpload: [Team] = []
        for id in Set(localByID.keys).union(remoteByID.keys) where !deleted.contains(id) {
            switch (localByID[id], remoteByID[id]) {
            case let (local?, remote?):
                if remote.updatedAt > local.updatedAt {
                    merged.append(remote)
                } else {
                    merged.append(local)
                    if local.updatedAt > remote.updatedAt { toUpload.append(local) }
                }
            case let (local?, nil):
                merged.append(local)
                toUpload.append(local)
            case let (nil, remote?):
                merged.append(remote)
            case (nil, nil):
                break
            }
        }

        // 3. Push local changes and deletions.
        let records = try toUpload.map(makeRecord)
        let deleteIDs = payload.deletedTeamIDs.map(Self.recordID)
        if !records.isEmpty || !deleteIDs.isEmpty {
            try await save(records: records, deleting: deleteIDs)
        }
        cleanUpTempFiles(for: toUpload)

        return SyncResult(
            teams: merged.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
            deletedTeamIDs: [],
            deletedPlayerIDs: [],
            lastSyncDate: Date()
        )
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
    private func fetchRemoteTeams() async throws -> [Team] {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        var teams: [Team] = []

        let first = try await database.records(matching: query)
        teams += decodeTeams(from: first.matchResults)
        var cursor = first.queryCursor
        while let next = cursor {
            let page = try await database.records(continuingMatchFrom: next)
            teams += decodeTeams(from: page.matchResults)
            cursor = page.queryCursor
        }
        return teams
    }

    private func decodeTeams(from results: [(CKRecord.ID, Result<CKRecord, Error>)]) -> [Team] {
        results.compactMap { _, result in
            guard case .success(let record) = result,
                  let asset = record["payload"] as? CKAsset,
                  let url = asset.fileURL,
                  let data = try? Data(contentsOf: url) else { return nil }
            do {
                return try JSONDecoder().decode(Team.self, from: data)
            } catch {
                print("⚠️ Skipping unreadable cloud team \(record.recordID.recordName):", error)
                return nil
            }
        }
    }

    private func save(records: [CKRecord], deleting ids: [CKRecord.ID]) async throws {
        let (saveResults, deleteResults) = try await database.modifyRecords(
            saving: records,
            deleting: ids,
            savePolicy: .allKeys,
            atomically: false
        )
        for (_, result) in saveResults {
            if case .failure(let error) = result { throw error }
        }
        for (_, result) in deleteResults {
            if case .failure(let error) = result {
                // Already gone is fine.
                if let ck = error as? CKError, ck.code == .unknownItem { continue }
                throw error
            }
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

    private func cleanUpTempFiles(for teams: [Team]) {
        for team in teams {
            try? FileManager.default.removeItem(at: tempURL(for: team))
        }
    }
}
