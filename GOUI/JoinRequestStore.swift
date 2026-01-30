import CloudKit
import Foundation

@MainActor
final class JoinRequestStore: ObservableObject {
    @Published private(set) var requests: [JoinRequest] = []

    private let container: CKContainer?
    private let database: CKDatabase?

    init(container: CKContainer? = CloudKitAvailability.defaultContainer()) {
        self.container = container
        self.database = container?.publicCloudDatabase
    }

    func refreshRequests(for teamID: UUID) async {
        guard cloudKitAvailable else {
            requests = []
            return
        }
        do {
            let predicate = NSPredicate(format: "teamID == %@", teamID.uuidString)
            let query = CKQuery(recordType: CloudRecordType.joinRequest, predicate: predicate)
            let records = try await fetchRecords(query: query)
            requests = records.compactMap(Self.decode)
        } catch {
            print("❌ JoinRequest fetch failed:", error)
        }
    }

    func submitJoinRequest(_ request: JoinRequest) async throws {
        guard cloudKitAvailable else { throw CloudKitUnavailableError() }
        let recordID = CKRecord.ID(recordName: request.id.uuidString)
        let record = CKRecord(recordType: CloudRecordType.joinRequest, recordID: recordID)
        record["teamID"] = request.teamID.uuidString as CKRecordValue
        record["teamName"] = request.teamName as CKRecordValue
        record["joinCode"] = request.joinCode as CKRecordValue
        record["requesterUserID"] = request.requesterUserID as CKRecordValue
        record["requesterName"] = request.requesterName as CKRecordValue
        record["requesterUserRecordName"] = (request.requesterUserRecordName ?? "") as CKRecordValue
        record["requestedMemberType"] = request.requestedMemberType.rawValue as CKRecordValue
        record["message"] = (request.message ?? "") as CKRecordValue
        record["status"] = request.status.rawValue as CKRecordValue
        record["createdAt"] = request.createdAt as CKRecordValue
        record["updatedAt"] = request.updatedAt as CKRecordValue
        _ = try await saveRecord(record)
    }

    func updateRequest(_ request: JoinRequest, status: JoinRequestStatus) async throws {
        guard cloudKitAvailable else { throw CloudKitUnavailableError() }
        let recordID = CKRecord.ID(recordName: request.id.uuidString)
        let record = CKRecord(recordType: CloudRecordType.joinRequest, recordID: recordID)
        record["teamID"] = request.teamID.uuidString as CKRecordValue
        record["teamName"] = request.teamName as CKRecordValue
        record["joinCode"] = request.joinCode as CKRecordValue
        record["requesterUserID"] = request.requesterUserID as CKRecordValue
        record["requesterName"] = request.requesterName as CKRecordValue
        record["requesterUserRecordName"] = (request.requesterUserRecordName ?? "") as CKRecordValue
        record["requestedMemberType"] = request.requestedMemberType.rawValue as CKRecordValue
        record["message"] = (request.message ?? "") as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["createdAt"] = request.createdAt as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await saveRecord(record)
    }

    func hasPendingRequest(teamID: UUID, userID: String) -> Bool {
        requests.contains { $0.teamID == teamID && $0.requesterUserID == userID && $0.status == .pending }
    }

    private func fetchRecords(query: CKQuery) async throws -> [CKRecord] {
        guard let database else { throw CloudKitUnavailableError() }
        return try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            var recordError: Error?
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

    private func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        guard let database else { throw CloudKitUnavailableError() }
        return try await withCheckedThrowingContinuation { continuation in
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

    private static func decode(record: CKRecord) -> JoinRequest? {
        guard let teamIDString = record["teamID"] as? String,
              let teamID = UUID(uuidString: teamIDString),
              let teamName = record["teamName"] as? String,
              let joinCode = record["joinCode"] as? String,
              let requesterUserID = record["requesterUserID"] as? String,
              let requestedMemberTypeRaw = (record["requestedMemberType"] as? String) ?? (record["requestedRole"] as? String),
              let statusRaw = record["status"] as? String,
              let status = JoinRequestStatus(rawValue: statusRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        let memberType = TeamMemberType(rawValue: requestedMemberTypeRaw) ?? {
            switch requestedMemberTypeRaw {
            case "coachManager", "coachStaff":
                return .coach
            case "parent":
                return .parent
            case "player":
                return .athlete
            default:
                return .athlete
            }
        }()
        let recordName = record.recordID.recordName
        return JoinRequest(
            id: UUID(uuidString: recordName) ?? UUID(),
            teamID: teamID,
            teamName: teamName,
            joinCode: joinCode,
            requesterUserID: requesterUserID,
            requesterName: (record["requesterName"] as? String) ?? "GoStats User",
            requesterUserRecordName: record["requesterUserRecordName"] as? String,
            requestedMemberType: memberType,
            message: record["message"] as? String,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private var cloudKitAvailable: Bool {
        container != nil && database != nil
    }
}
