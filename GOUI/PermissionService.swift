import Foundation

final class PermissionService: ObservableObject {
    private let roleManager: RoleManager
    private let membershipStore: TeamMembershipStore
    private let subscriptionManager: SubscriptionManager

    init(roleManager: RoleManager, membershipStore: TeamMembershipStore, subscriptionManager: SubscriptionManager) {
        self.roleManager = roleManager
        self.membershipStore = membershipStore
        self.subscriptionManager = subscriptionManager
    }

    func canEditRoster(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        return membershipRole(for: teamID) == .coachManager
    }

    func canLogMatches(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        let role = membershipRole(for: teamID)
        return role == .coachManager || role == .coachStaff
    }

    func canExport(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        let role = membershipRole(for: teamID)
        return role == .coachManager || role == .coachStaff
    }

    func canManageMembers(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        return membershipRole(for: teamID) == .coachManager
    }

    func membershipRole(for teamID: UUID) -> TeamMembershipRole? {
        membershipStore.membership(for: teamID, userID: roleManager.userID)?.membershipRole
    }

    func coachLimitMessage() -> String {
        "Coach membership includes 1 team. Upgrade to Club or remove coach access from another team."
    }

    func canAssignCoachRole(teamID: UUID, role: TeamMembershipRole) -> Bool {
        membershipStore.canGrantCoachRole(
            userID: roleManager.userID,
            newRole: role,
            teamID: teamID,
            userRole: roleManager.role,
            currentPlan: subscriptionManager.currentPlan
        )
    }
}
