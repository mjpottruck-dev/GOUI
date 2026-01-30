import CloudKit
import Foundation

final class TeamMembershipStore: ObservableObject {
    @Published private(set) var memberships: [TeamMembership] = [] {
        didSet {
            save()
            if cloudSyncEnabled && !isApplyingSync {
                scheduleSync()
            }
        }
    }

    private let fileURL: URL
    private var cloudSyncEnabled = false
    private var syncTask: Task<Void, Never>? = nil
    private var isApplyingSync = false
    private var syncManager: CloudMembershipSyncManager?

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("team_memberships.json")
        syncManager = CloudMembershipSyncManager.makeIfAvailable()
        load()
    }

    func updateCloudSyncEnabled(_ enabled: Bool) {
        cloudSyncEnabled = enabled
        if enabled {
            scheduleSync()
        }
    }

    func bootstrapMemberships(for teamStore: TeamStore, userID: String, defaultRole: TeamPermissionRole) {
        let teamIDs = Set(teamStore.teams.map(\.id))
        let existing = Set(memberships.filter { $0.userID == userID && $0.status == .active }.map(\.teamID))
        let missing = teamIDs.subtracting(existing)
        guard !missing.isEmpty else { return }

        let now = Date()
        let newMemberships = missing.map { teamID in
            TeamMembership(
                teamID: teamID,
                userID: userID,
                memberType: .coach,
                permissionRole: defaultRole,
                createdAt: now,
                updatedAt: now,
                status: .active
            )
        }
        memberships.append(contentsOf: newMemberships)
    }

    func memberships(for userID: String) -> [TeamMembership] {
        memberships.filter { $0.userID == userID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func activeMemberships(for userID: String) -> [TeamMembership] {
        memberships.filter { $0.userID == userID && $0.status == .active }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func activeTeamIDs(for userID: String) -> [UUID] {
        activeMemberships(for: userID).map(\.teamID)
    }

    func membership(for teamID: UUID, userID: String) -> TeamMembership? {
        memberships.first { $0.teamID == teamID && $0.userID == userID && $0.status == .active }
    }

    func membershipRecord(for teamID: UUID, userID: String) -> TeamMembership? {
        memberships.first { $0.teamID == teamID && $0.userID == userID }
    }

    func memberships(for teamID: UUID) -> [TeamMembership] {
        memberships.filter { $0.teamID == teamID && $0.status != .removed }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func requestJoin(teamID: UUID, userID: String, memberType: TeamMemberType, permissionRole: TeamPermissionRole) {
        let now = Date()
        let membership = TeamMembership(
            teamID: teamID,
            userID: userID,
            memberType: memberType,
            permissionRole: permissionRole,
            createdAt: now,
            updatedAt: now,
            status: .pending
        )
        memberships.append(membership)
    }

    func approveMembership(_ membership: TeamMembership) {
        updateMembership(membership, status: .active)
    }

    func updateMembership(_ membership: TeamMembership, status: TeamMembershipStatus? = nil, role: TeamPermissionRole? = nil, memberType: TeamMemberType? = nil) {
        guard let idx = memberships.firstIndex(where: { $0.id == membership.id }) else { return }
        var updated = memberships[idx]
        if let status { updated.status = status }
        if let role { updated.permissionRole = role }
        if let memberType { updated.memberType = memberType }
        updated.updatedAt = Date()
        memberships[idx] = updated
    }

    func removeMembership(_ membership: TeamMembership) {
        updateMembership(membership, status: .removed)
    }

    func canGrantCoachRole(
        userID: String,
        newRole: TeamPermissionRole,
        teamID: UUID,
        userRole: UserRole,
        currentPlan: Plan
    ) -> Bool {
        guard userRole == .coach, newRole.hasCoachPermissions else { return true }
        guard currentPlan == .coachPro else { return true }
        let activeCoachMemberships = activeMemberships(for: userID)
            .filter { $0.permissionRole.hasCoachPermissions && $0.teamID != teamID }
        return activeCoachMemberships.isEmpty
    }

    func activeCoachTeam(for userID: String) -> TeamMembership? {
        activeMemberships(for: userID).first { $0.permissionRole.hasCoachPermissions }
    }

    private func scheduleSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            await self?.syncWithCloud()
        }
    }

    @MainActor
    private func syncWithCloud() async {
        guard let syncManager, cloudSyncEnabled, !isApplyingSync else { return }
        isApplyingSync = true
        defer { isApplyingSync = false }
        do {
            let remote = try await syncManager.sync(memberships: memberships)
            memberships = remote
        } catch {
            print("❌ Membership sync failed:", error)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([TeamMembership].self, from: data) else {
            memberships = []
            return
        }
        memberships = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(memberships) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

final class CloudMembershipSyncManager {
    private let database: CKDatabase

    static func makeIfAvailable() -> CloudMembershipSyncManager? {
        guard CloudSyncManager.isAvailable else { return nil }
        return CloudMembershipSyncManager()
    }

    init(container: CKContainer = CKContainer.default()) {
        database = container.privateCloudDatabase
    }

    func sync(memberships: [TeamMembership]) async throws -> [TeamMembership] {
        let records = memberships.map { membership in
            let recordID = CKRecord.ID(recordName: membership.id.uuidString)
            let record = CKRecord(recordType: "TeamMembership", recordID: recordID)
            record["teamID"] = membership.teamID.uuidString as CKRecordValue
            record["userID"] = membership.userID as CKRecordValue
            record["membershipRole"] = membership.permissionRole.rawValue as CKRecordValue
            record["memberType"] = membership.memberType.rawValue as CKRecordValue
            record["status"] = membership.status.rawValue as CKRecordValue
            record["createdAt"] = membership.createdAt as CKRecordValue
            record["updatedAt"] = membership.updatedAt as CKRecordValue
            return record
        }

        try await modifyRecords(recordsToSave: records, recordIDsToDelete: [])
        return try await fetchMemberships()
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

    private func fetchMemberships() async throws -> [TeamMembership] {
        let query = CKQuery(recordType: "TeamMembership", predicate: NSPredicate(value: true))
        let records = try await fetchRecords(query: query)
        return records.compactMap { record in
            guard let teamIDString = record["teamID"] as? String,
                  let teamID = UUID(uuidString: teamIDString),
                  let userID = record["userID"] as? String,
                  let roleRaw = record["membershipRole"] as? String,
                  let role = TeamPermissionRole(rawValue: roleRaw),
                  let statusRaw = record["status"] as? String,
                  let status = TeamMembershipStatus(rawValue: statusRaw),
                  let createdAt = record["createdAt"] as? Date,
                  let updatedAt = record["updatedAt"] as? Date,
                  let id = UUID(uuidString: record.recordID.recordName)
            else { return nil }
            let memberTypeRaw = record["memberType"] as? String
            let memberType = TeamMemberType(rawValue: memberTypeRaw ?? "") ?? .athlete
            return TeamMembership(
                id: id,
                teamID: teamID,
                userID: userID,
                memberType: memberType,
                permissionRole: role,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status
            )
        }
    }

    private func fetchRecords(query: CKQuery) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
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
}
