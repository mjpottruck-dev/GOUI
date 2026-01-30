import Foundation

enum UserRole: String, CaseIterable, Codable, Identifiable {
    case athlete
    case parent
    case coach
    case recruiter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .athlete: return "Athlete / Student"
        case .parent: return "Parent / Family"
        case .coach: return "Coach / Manager"
        case .recruiter: return "Recruiter"
        }
    }

    var permissionsSummary: String {
        switch self {
        case .athlete:
            return "View team updates, schedule, stats, and chat."
        case .parent:
            return "Follow teams, chat, and request stat keeper access."
        case .coach:
            return "Manage rosters, log games, approve requests, export stats."
        case .recruiter:
            return "Search public player profiles in read-only mode."
        }
    }

    static func fromStoredValue(_ raw: String) -> UserRole? {
        if let role = UserRole(rawValue: raw) {
            return role
        }
        switch raw {
        case "familyMember":
            return .parent
        default:
            return nil
        }
    }
}

struct UserIdentity: Codable {
    var deviceUserID: String
    var displayName: String
    var selectedRole: UserRole
    var affiliatedTeamIDs: [UUID]
    var affiliatedClubID: UUID?
    var createdAt: Date
}

private struct LegacyUserProfile: Codable {
    var userID: String?
    var displayName: String?
    var role: String?
    var affiliatedTeamIDs: [UUID]?
    var affiliatedClubID: UUID?
    var createdAt: Date?
}

@MainActor
final class UserIdentityManager: ObservableObject {
    @Published private(set) var deviceUserID: String
    @Published var displayName: String {
        didSet { save() }
    }
    @Published var selectedRole: UserRole {
        didSet { save() }
    }
    @Published private(set) var affiliatedTeamIDs: [UUID] {
        didSet { save() }
    }
    @Published private(set) var affiliatedClubID: UUID? {
        didSet { save() }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey) }
    }

    private let fileURL: URL
    private let userIDKey = "gostats.deviceUserID"
    private let onboardingKey = "onboarding.completed"
    private let createdAtKey = "gostats.createdAt"

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("user_identity.json")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        if let stored = KeychainHelper.read(userIDKey) {
            deviceUserID = stored
        } else {
            let newID = UUID().uuidString
            KeychainHelper.save(newID, for: userIDKey)
            deviceUserID = newID
        }

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(UserIdentity.self, from: data) {
            displayName = decoded.displayName
            selectedRole = decoded.selectedRole
            affiliatedTeamIDs = decoded.affiliatedTeamIDs
            affiliatedClubID = decoded.affiliatedClubID
        } else if let data = try? Data(contentsOf: fileURL),
                  let legacy = try? JSONDecoder().decode(LegacyUserProfile.self, from: data) {
            displayName = legacy.displayName ?? "GoStats User"
            selectedRole = UserRole.fromStoredValue(legacy.role ?? "") ?? .athlete
            affiliatedTeamIDs = legacy.affiliatedTeamIDs ?? []
            affiliatedClubID = legacy.affiliatedClubID
        } else {
            displayName = "GoStats User"
            selectedRole = .athlete
            affiliatedTeamIDs = []
            affiliatedClubID = nil
        }
    }

    var createdAt: Date {
        if let stored = UserDefaults.standard.object(forKey: createdAtKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: createdAtKey)
        return now
    }

    var userID: String { deviceUserID }

    var role: UserRole {
        selectedRole
    }

    var needsOnboarding: Bool {
        !hasCompletedOnboarding
    }

    func setRole(_ role: UserRole) {
        selectedRole = role
    }

    func updateDisplayName(_ name: String) {
        displayName = name
    }

    func updateAffiliatedTeams(_ ids: [UUID]) {
        affiliatedTeamIDs = ids
    }

    func updateClub(_ clubID: UUID?) {
        affiliatedClubID = clubID
    }

    func applyAuthUser(_ authUser: AuthUser?) {
        guard let authUser else { return }
        if displayName == "GoStats User" {
            displayName = authUser.displayName
        }
        if selectedRole != authUser.role {
            selectedRole = authUser.role
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    private func save() {
        let identity = UserIdentity(
            deviceUserID: deviceUserID,
            displayName: displayName,
            selectedRole: selectedRole,
            affiliatedTeamIDs: affiliatedTeamIDs,
            affiliatedClubID: affiliatedClubID,
            createdAt: createdAt
        )
        if let data = try? JSONEncoder().encode(identity) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }
}

// Backwards compatibility for existing references.
typealias RoleManager = UserIdentityManager
