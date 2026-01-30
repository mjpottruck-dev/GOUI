import Foundation

enum UserRole: String, CaseIterable, Codable, Identifiable {
    case familyMember
    case coach
    case recruiter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .familyMember: return "Family Member"
        case .coach: return "Coach"
        case .recruiter: return "Recruiter"
        }
    }

    var permissionsSummary: String {
        switch self {
        case .familyMember:
            return "View teams, stats, and highlights."
        case .coach:
            return "Edit rosters, log games, export stats."
        case .recruiter:
            return "Search public player profiles in read-only mode."
        }
    }
}

struct UserProfile: Identifiable, Codable {
    var id: String { userID }
    var userID: String
    var displayName: String
    var role: UserRole
    var affiliatedTeamIDs: [UUID]
    var affiliatedClubID: UUID?
    var createdAt: Date
}

private struct LegacyUserProfile: Codable {
    var id: UUID
    var role: UserRole
    var affiliatedTeamIDs: [UUID]
    var affiliatedClubID: UUID?
    var createdAt: Date
}

final class RoleManager: ObservableObject {
    @Published private(set) var profile: UserProfile? {
        didSet { save() }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey) }
    }

    private let fileURL: URL
    private let userIDKey = "gostats.userID"
    private let onboardingKey = "onboarding.completed"

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("user_profile.json")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        load()
    }

    var userID: String {
        if let stored = KeychainHelper.read(userIDKey) {
            return stored
        }
        let newID = UUID().uuidString
        KeychainHelper.save(newID, for: userIDKey)
        return newID
    }

    var role: UserRole {
        profile?.role ?? .familyMember
    }

    var needsOnboarding: Bool {
        profile == nil || !hasCompletedOnboarding
    }

    func setRole(_ role: UserRole) {
        var updated = profile ?? UserProfile(
            userID: userID,
            displayName: profile?.displayName ?? "GoStats User",
            role: role,
            affiliatedTeamIDs: [],
            affiliatedClubID: nil,
            createdAt: Date()
        )
        updated.role = role
        profile = updated
    }

    func updateDisplayName(_ displayName: String) {
        var updated = profile ?? UserProfile(
            userID: userID,
            displayName: displayName,
            role: .familyMember,
            affiliatedTeamIDs: [],
            affiliatedClubID: nil,
            createdAt: Date()
        )
        updated.displayName = displayName
        profile = updated
    }

    func updateAffiliatedTeams(_ ids: [UUID]) {
        guard var profile else { return }
        profile.affiliatedTeamIDs = ids
        self.profile = profile
    }

    func updateClub(_ clubID: UUID?) {
        guard var profile else { return }
        profile.affiliatedClubID = clubID
        self.profile = profile
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    func canEditRoster() -> Bool {
        role == .coach
    }

    func canLogGames() -> Bool {
        role == .coach
    }

    func canExport() -> Bool {
        role == .coach
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }

        if let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
            return
        }

        if let legacy = try? JSONDecoder().decode(LegacyUserProfile.self, from: data) {
            profile = UserProfile(
                userID: userID,
                displayName: "GoStats User",
                role: legacy.role,
                affiliatedTeamIDs: legacy.affiliatedTeamIDs,
                affiliatedClubID: legacy.affiliatedClubID,
                createdAt: legacy.createdAt
            )
        }
    }

    private func save() {
        guard let profile else { return }
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }
}
