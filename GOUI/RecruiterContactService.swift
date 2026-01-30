import CloudKit
import Foundation

final class RecruiterContactService {
    private let database: CKDatabase

    init(container: CKContainer = CKContainer.default()) {
        database = container.privateCloudDatabase
    }

    func sendContactRequest(teamID: UUID, playerID: UUID, recruiterUserID: String) async throws {
        let record = CKRecord(recordType: CloudRecordType.recruiterNotification)
        record["teamID"] = teamID.uuidString as CKRecordValue
        record["playerID"] = playerID.uuidString as CKRecordValue
        record["recruiterUserID"] = recruiterUserID as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        _ = try await saveRecord(record)
    }

    private func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.save(record) { saved, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let saved {
                    continuation.resume(returning: saved)
                } else {
                    continuation.resume(throwing: CKError(.unknownItem))
                }
            }
        }
    }
}
