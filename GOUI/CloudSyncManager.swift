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

final class CloudSyncManager {
    private let database: CKDatabase

    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    static func makeIfAvailable() -> CloudSyncManager? {
        guard isAvailable else { return nil }
        return CloudSyncManager()
    }

    init(container: CKContainer = CKContainer.default()) {
        self.database = container.privateCloudDatabase
    }

    func sync(payload: SyncPayload, localMatches: [UUID: [MatchRecord]]) async throws -> SyncResult {
        let recordsToSave = makeRecords(from: payload.teams)
        let recordIDsToDelete = payload.deletedTeamIDs.map { CKRecord.ID(recordName: $0.uuidString) }
            + payload.deletedPlayerIDs.map { CKRecord.ID(recordName: $0.uuidString) }

        if !recordsToSave.isEmpty || !recordIDsToDelete.isEmpty {
            try await modifyRecords(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        }

        let fetchedTeams = try await fetchRecords(ofType: "Team")
        let fetchedPlayers = try await fetchRecords(ofType: "Player")

        let mergedTeams = mergeTeams(
            localTeams: payload.teams,
            remoteTeams: fetchedTeams,
            remotePlayers: fetchedPlayers,
            localMatches: localMatches
        )

        return SyncResult(
            teams: mergedTeams,
            deletedTeamIDs: [],
            deletedPlayerIDs: [],
            lastSyncDate: Date()
        )
    }

    private func modifyRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecord.ID]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
            operation.savePolicy = .allKeys
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    private func fetchRecords(ofType type: String) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
            var records: [CKRecord] = []
            var recordError: Error?
            let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
            let operation = CKQueryOperation(query: query)
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    records.append(record)
                case .failure(let error):
                    recordError = error
                }
            }
            operation.queryResultBlock = { result in
                if let recordError {
                    continuation.resume(throwing: recordError)
                    return
                }
                switch result {
                case .success:
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    private func makeRecords(from teams: [Team]) -> [CKRecord] {
        var records: [CKRecord] = []
        for team in teams {
            let recordID = CKRecord.ID(recordName: team.id.uuidString)
            let teamRecord = CKRecord(recordType: "Team", recordID: recordID)
            teamRecord["name"] = team.name as CKRecordValue
            teamRecord["sportID"] = team.sportID as CKRecordValue
            teamRecord["joinCode"] = team.joinCode as CKRecordValue
            teamRecord["requiresApprovalToJoin"] = team.requiresApprovalToJoin as CKRecordValue
            teamRecord["shareRecordName"] = (team.shareRecordName ?? "") as CKRecordValue
            teamRecord["createdAt"] = team.createdAt as CKRecordValue
            teamRecord["updatedAt"] = team.updatedAt as CKRecordValue
            records.append(teamRecord)

            for player in team.players {
                let playerID = CKRecord.ID(recordName: player.id.uuidString)
                let playerRecord = CKRecord(recordType: "Player", recordID: playerID)
                playerRecord["teamID"] = team.id.uuidString as CKRecordValue
                playerRecord["name"] = player.name as CKRecordValue
                playerRecord["number"] = player.number as CKRecordValue
                playerRecord["position"] = (player.positionName ?? player.position.rawValue) as CKRecordValue
                playerRecord["isGoalie"] = (player.isGoalie ?? player.derivedIsGoalie) as CKRecordValue
                playerRecord["notes"] = (player.notes ?? "") as CKRecordValue
                playerRecord["createdAt"] = player.createdAt as CKRecordValue
                playerRecord["updatedAt"] = player.updatedAt as CKRecordValue
                if let profileData = try? JSONEncoder().encode(player.profile),
                   let profileString = String(data: profileData, encoding: .utf8) {
                    playerRecord["profileData"] = profileString as CKRecordValue
                }
                records.append(playerRecord)
            }
        }
        return records
    }

    private func mergeTeams(
        localTeams: [Team],
        remoteTeams: [CKRecord],
        remotePlayers: [CKRecord],
        localMatches: [UUID: [MatchRecord]]
    ) -> [Team] {
        let localByID = Dictionary(uniqueKeysWithValues: localTeams.map { ($0.id, $0) })
        let remoteTeamsByID: [UUID: CKRecord] = Dictionary(
            uniqueKeysWithValues: remoteTeams.compactMap { record -> (UUID, CKRecord)? in
                guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
                return (id, record)
            }
        )

        var playersByTeam: [UUID: [Player]] = [:]
        for record in remotePlayers {
            guard let teamIDString = record["teamID"] as? String,
                  let teamID = UUID(uuidString: teamIDString),
                  let player = decodePlayer(from: record)
            else { continue }
            playersByTeam[teamID, default: []].append(player)
        }

        var merged: [Team] = []
        let allIDs = Set(localByID.keys).union(remoteTeamsByID.keys)

        for id in allIDs {
            let local = localByID[id]
            let remote = remoteTeamsByID[id]

            if let remote, let remoteTeam = decodeTeam(from: remote, players: playersByTeam[id] ?? []) {
                if let local {
                    if shouldPreferRemote(local: local, remote: remoteTeam) {
                        if local.updatedAt != remoteTeam.updatedAt {
                            print("⚠️ Cloud conflict (team \(id)): remote wins.")
                        }
                        var mergedTeam = remoteTeam
                        mergedTeam.matches = local.matches
                        merged.append(mergedTeam)
                    } else {
                        if local.updatedAt != remoteTeam.updatedAt {
                            print("⚠️ Cloud conflict (team \(id)): local wins.")
                        }
                        merged.append(local)
                    }
                } else {
                    var mergedTeam = remoteTeam
                    if let matches = localMatches[id] {
                        mergedTeam.matches = matches
                    }
                    merged.append(mergedTeam)
                }
            } else if let local {
                merged.append(local)
            }
        }

        return merged.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func shouldPreferRemote(local: Team, remote: Team) -> Bool {
        if remote.updatedAt == local.updatedAt {
            return false
        }
        return remote.updatedAt > local.updatedAt
    }

    private func decodeTeam(from record: CKRecord, players: [Player]) -> Team? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        let sportID = record["sportID"] as? String ?? SportCatalog.defaultSportID
        let joinCode = record["joinCode"] as? String ?? Team.makeJoinCode()
        let requiresApproval = record["requiresApprovalToJoin"] as? Bool ?? true
        let shareRecordName = record["shareRecordName"] as? String
        var team = Team(
            id: id,
            name: name,
            players: players,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sportID: sportID,
            joinCode: joinCode,
            requiresApprovalToJoin: requiresApproval,
            shareRecordName: shareRecordName?.isEmpty == true ? nil : shareRecordName
        )
        team.matches = []
        return team
    }

    private func decodePlayer(from record: CKRecord) -> Player? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String,
              let number = record["number"] as? Int,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        let positionName = record["position"] as? String
        let isGoalie = record["isGoalie"] as? Bool
        let notes = record["notes"] as? String
        let resolvedPosition = Position(rawValue: positionName ?? "") ?? .cm
        let profile: PlayerProfile
        if let profileString = record["profileData"] as? String,
           let data = profileString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = decoded
        } else {
            profile = PlayerProfile()
        }
        return Player(
            id: id,
            name: name,
            number: number,
            jersey: "\(number)",
            position: resolvedPosition,
            secondaryPosition: nil,
            positionName: positionName,
            isGoalie: isGoalie,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profile: profile
        )
    }
}
