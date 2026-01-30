import Foundation

enum JoinRequestStatus: String, CaseIterable, Codable, Identifiable {
    case pending
    case approved
    case denied

    var id: String { rawValue }
}

struct JoinRequest: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var teamID: UUID
    var teamName: String
    var joinCode: String
    var requesterUserID: String
    var requesterName: String
    var requesterUserRecordName: String?
    var requestedMemberType: TeamMemberType
    var message: String?
    var status: JoinRequestStatus = .pending
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct StatKeeperRequest: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var teamID: UUID
    var requestedByUserID: String
    var requestedByName: String
    var message: String?
    var status: JoinRequestStatus = .pending
    var reviewedByUserID: String?
    var reviewedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
