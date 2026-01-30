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
    var requesterUserRecordName: String?
    var requestedRole: TeamMembershipRole
    var status: JoinRequestStatus = .pending
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
