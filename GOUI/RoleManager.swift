import Foundation

enum UserRole: String, CaseIterable, Codable, Identifiable {
    case parentPlayer
    case coach
    case clubAdmin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .parentPlayer: return "Parent / Player"
        case .coach: return "Coach"
        case .clubAdmin: return "Club Admin"
        }
    }

    var permissionsSummary: String {
        switch self {
        case .parentPlayer:
            return "View teams, stats, and highlights."
        case .coach:
            return "Edit rosters, log games, export stats."
        case .clubAdmin:
            return "Manage multiple teams and club settings."
        }
    }
}

struct UserProfile: Identifiable, Codable {
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
    private let onboardingKey = "onboarding.completed"

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("user_profile.json")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        load()
    }

    var role: UserRole {
        profile?.role ?? .parentPlayer
    }

    var needsOnboarding: Bool {
        profile == nil || !hasCompletedOnboarding
    }

    func setRole(_ role: UserRole) {
        var updated = profile ?? UserProfile(
            id: UUID(),
            role: role,
            affiliatedTeamIDs: [],
            affiliatedClubID: nil,
            createdAt: Date()
        )
        updated.role = role
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
        role == .coach || role == .clubAdmin
    }

    func canLogGames() -> Bool {
        role == .coach || role == .clubAdmin
    }

    func canExport() -> Bool {
        role == .coach || role == .clubAdmin
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }
        profile = decoded
    }

    private func save() {
        guard let profile else { return }
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }
}
