import Foundation

enum TeamMemberType: String, CaseIterable, Codable, Identifiable {
    case athlete
    case parent
    case family
    case coach
    case recruiterViewer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .athlete: return "Athlete"
        case .parent: return "Parent"
        case .family: return "Family"
        case .coach: return "Coach"
        case .recruiterViewer: return "Recruiter"
        }
    }
}

enum TeamPermissionRole: String, CaseIterable, Codable, Identifiable {
    case viewer
    case statKeeper
    case coachStaff
    case coachManager
    case manager

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .viewer: return "Viewer"
        case .statKeeper: return "Stat Keeper"
        case .coachStaff: return "Coach Staff"
        case .coachManager: return "Coach Manager"
        case .manager: return "Manager"
        }
    }

    var hasCoachPermissions: Bool {
        self == .coachStaff || self == .coachManager || self == .manager
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
    var memberType: TeamMemberType
    var permissionRole: TeamPermissionRole
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var status: TeamMembershipStatus = .active

    enum CodingKeys: String, CodingKey {
        case id
        case teamID
        case userID
        case memberType
        case permissionRole
        case createdAt
        case updatedAt
        case status
        case membershipRole
    }

    init(
        id: UUID = UUID(),
        teamID: UUID,
        userID: String,
        memberType: TeamMemberType,
        permissionRole: TeamPermissionRole,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: TeamMembershipStatus = .active
    ) {
        self.id = id
        self.teamID = teamID
        self.userID = userID
        self.memberType = memberType
        self.permissionRole = permissionRole
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        teamID = try container.decode(UUID.self, forKey: .teamID)
        userID = try container.decode(String.self, forKey: .userID)
        memberType = try container.decodeIfPresent(TeamMemberType.self, forKey: .memberType) ?? .athlete
        permissionRole = try container.decodeIfPresent(TeamPermissionRole.self, forKey: .permissionRole) ?? .viewer
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        status = try container.decodeIfPresent(TeamMembershipStatus.self, forKey: .status) ?? .active

        if container.contains(.membershipRole) {
            let legacyRaw = try container.decode(String.self, forKey: .membershipRole)
            switch legacyRaw {
            case "coachManager":
                permissionRole = .coachManager
                memberType = .coach
            case "coachStaff":
                permissionRole = .coachStaff
                memberType = .coach
            case "parent":
                permissionRole = .viewer
                memberType = .parent
            case "player":
                permissionRole = .viewer
                memberType = .athlete
            default:
                permissionRole = .viewer
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(teamID, forKey: .teamID)
        try container.encode(userID, forKey: .userID)
        try container.encode(memberType, forKey: .memberType)
        try container.encode(permissionRole, forKey: .permissionRole)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(status, forKey: .status)
    }
}
