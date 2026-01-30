import Foundation

enum TeamMembershipRole: String, CaseIterable, Codable, Identifiable {
    case viewer
    case player
    case parent
    case coachManager
    case coachStaff

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .viewer: return "Viewer"
        case .player: return "Player"
        case .parent: return "Parent"
        case .coachManager: return "Coach Manager"
        case .coachStaff: return "Coach Staff"
        }
    }

    var hasCoachPermissions: Bool {
        self == .coachManager || self == .coachStaff
    }
}

enum TeamMembershipStatus: String, CaseIterable, Codable, Identifiable {
    case active
    case pending
    case removed

    var id: String { rawValue }
}

struct TeamMembership: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var teamID: UUID
    var userID: String
    var membershipRole: TeamMembershipRole
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var status: TeamMembershipStatus = .active
}
