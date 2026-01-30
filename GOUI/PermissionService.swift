import Foundation

@MainActor
final class PermissionService: ObservableObject {
    private let roleManager: RoleManager
    private let membershipStore: TeamMembershipStore
    private let subscriptionManager: SubscriptionManager

    init(roleManager: RoleManager, membershipStore: TeamMembershipStore, subscriptionManager: SubscriptionManager) {
        self.roleManager = roleManager
        self.membershipStore = membershipStore
        self.subscriptionManager = subscriptionManager
    }

    func canViewTeam(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        return membershipRole(for: teamID) != nil
    }

    func canChat(teamID: UUID) -> Bool {
        canViewTeam(teamID: teamID)
    }

    func canLogMatches(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        let role = membershipRole(for: teamID)
        return role == .coachManager || role == .coachStaff || role == .statKeeper || role == .manager
    }

    func canEditRoster(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        return membershipRole(for: teamID) == .coachManager || membershipRole(for: teamID) == .manager
    }

    func canManageMembers(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        return membershipRole(for: teamID) == .coachManager || membershipRole(for: teamID) == .manager
    }

    func canApproveJoinRequests(teamID: UUID) -> Bool {
        canManageMembers(teamID: teamID)
    }

    func canApproveStatKeepers(teamID: UUID) -> Bool {
        canManageMembers(teamID: teamID)
    }

    func canExport(teamID: UUID) -> Bool {
        guard roleManager.role != .recruiter else { return false }
        let role = membershipRole(for: teamID)
        return role == .coachManager || role == .coachStaff || role == .statKeeper || role == .manager
    }

    func membershipRole(for teamID: UUID) -> TeamPermissionRole? {
        membershipStore.membership(for: teamID, userID: roleManager.userID)?.permissionRole
    }

    func coachLimitMessage() -> String {
        "Coach membership includes 1 team. Upgrade to Club or remove coach access from another team."
    }

    func canAssignCoachRole(teamID: UUID, role: TeamPermissionRole) -> Bool {
        membershipStore.canGrantCoachRole(
            userID: roleManager.userID,
            newRole: role,
            teamID: teamID,
            userRole: roleManager.role,
            currentPlan: subscriptionManager.currentPlan
        )
    }
}
