import CloudKit
import Foundation

final class SharingService: ObservableObject {
    private let container: CKContainer
    private let database: CKDatabase

    init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.database = container.privateCloudDatabase
    }

    func createShare(for team: Team) async throws -> CKShare {
        let recordID = CKRecord.ID(recordName: team.id.uuidString)
        let teamRecord = CKRecord(recordType: CloudRecordType.team, recordID: recordID)
        teamRecord["name"] = team.name as CKRecordValue
        teamRecord["sportID"] = team.sportID as CKRecordValue
        teamRecord["joinCode"] = team.joinCode as CKRecordValue
        teamRecord["requiresApprovalToJoin"] = team.requiresApprovalToJoin as CKRecordValue
        teamRecord["createdAt"] = team.createdAt as CKRecordValue
        teamRecord["updatedAt"] = team.updatedAt as CKRecordValue

        let share = CKShare(rootRecord: teamRecord)
        share[CKShare.SystemFieldKey.title] = team.name as CKRecordValue
        share.publicPermission = .none

        try await modifyRecords(recordsToSave: [teamRecord, share])
        return share
    }

    func addParticipant(
        shareRecordName: String,
        userRecordName: String,
        permission: CKShare.ParticipantPermission
    ) async throws {
        let shareID = CKRecord.ID(recordName: shareRecordName)
        let share = try await fetchShare(recordID: shareID)
        let userRecordID = CKRecord.ID(recordName: userRecordName)
        let participant = try await fetchParticipant(userRecordID: userRecordID)
        participant.permission = permission
        share.addParticipant(participant)
        try await modifyRecords(recordsToSave: [share])
    }

    func removeParticipant(
        shareRecordName: String,
        userRecordName: String
    ) async throws {
        let shareID = CKRecord.ID(recordName: shareRecordName)
        let share = try await fetchShare(recordID: shareID)
        share.participants.removeAll { $0.userIdentity.userRecordID?.recordName == userRecordName }
        try await modifyRecords(recordsToSave: [share])
    }

    private func fetchShare(recordID: CKRecord.ID) async throws -> CKShare {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: recordID) { record, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let share = record as? CKShare else {
                    continuation.resume(throwing: CKError(.unknownItem))
                    return
                }
                continuation.resume(returning: share)
            }
        }
    }

    private func fetchParticipant(userRecordID: CKRecord.ID) async throws -> CKShare.Participant {
        try await withCheckedThrowingContinuation { continuation in
            container.fetchShareParticipant(withUserRecordID: userRecordID) { participant, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let participant {
                    continuation.resume(returning: participant)
                } else {
                    continuation.resume(throwing: CKError(.unknownItem))
                }
            }
        }
    }

    private func modifyRecords(recordsToSave: [CKRecord]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
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
}
