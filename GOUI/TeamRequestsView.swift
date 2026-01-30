import SwiftUI

struct TeamRequestsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @EnvironmentObject var joinRequestStore: JoinRequestStore
    @EnvironmentObject var statKeeperRequestStore: StatKeeperRequestStore
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService
    @EnvironmentObject var roleManager: RoleManager

    @State private var selectedJoinRequest: JoinRequest?
    @State private var selectedMemberType: TeamMemberType = .athlete
    @State private var selectedPermissionRole: TeamPermissionRole = .viewer
    @State private var showApprovalSheet = false

    var body: some View {
        List {
            Section("Join Requests") {
                if joinRequests.isEmpty {
                    Text("No pending join requests.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(joinRequests) { request in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(request.requesterName)
                                .font(.headline)
                            Text("Requested as \(request.requestedMemberType.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let message = request.message, !message.isEmpty {
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Button("Approve") {
                                    prepareApproval(for: request)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Deny", role: .destructive) {
                                    Task { await deny(request) }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Stat Keeper Requests") {
                if statKeeperRequests.isEmpty {
                    Text("No stat keeper requests.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(statKeeperRequests) { request in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(request.requestedByName)
                                .font(.headline)
                            if let message = request.message, !message.isEmpty {
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Button("Approve") {
                                    approveStatKeeper(request)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Deny", role: .destructive) {
                                    denyStatKeeper(request)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Requests")
        .task {
            await joinRequestStore.refreshRequests(for: teamID)
        }
        .sheet(isPresented: $showApprovalSheet) {
            NavigationStack {
                Form {
                    Section("Member Type") {
                        Picker("Type", selection: $selectedMemberType) {
                            ForEach(TeamMemberType.allCases) { memberType in
                                Text(memberType.displayName).tag(memberType)
                            }
                        }
                    }
                    Section("Permission") {
                        Picker("Role", selection: $selectedPermissionRole) {
                            ForEach(TeamPermissionRole.allCases) { role in
                                Text(role.displayName).tag(role)
                            }
                        }
                    }
                }
                .navigationTitle("Approve Request")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showApprovalSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Approve") {
                            if let request = selectedJoinRequest {
                                Task { await approve(request) }
                            }
                            showApprovalSheet = false
                        }
                    }
                }
            }
        }
    }

    private var joinRequests: [JoinRequest] {
        joinRequestStore.requests.filter { $0.teamID == teamID && $0.status == .pending }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var statKeeperRequests: [StatKeeperRequest] {
        statKeeperRequestStore.requests(for: teamID).filter { $0.status == .pending }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func prepareApproval(for request: JoinRequest) {
        selectedJoinRequest = request
        selectedMemberType = request.requestedMemberType
        selectedPermissionRole = request.requestedMemberType == .coach ? .coachStaff : .viewer
        showApprovalSheet = true
    }

    private func approve(_ request: JoinRequest) async {
        if let existing = membershipStore.membershipRecord(for: teamID, userID: request.requesterUserID) {
            membershipStore.updateMembership(existing, status: .active, role: selectedPermissionRole, memberType: selectedMemberType)
        } else {
            membershipStore.requestJoin(teamID: teamID, userID: request.requesterUserID, memberType: selectedMemberType, permissionRole: selectedPermissionRole)
            if let pending = membershipStore.membershipRecord(for: teamID, userID: request.requesterUserID) {
                membershipStore.approveMembership(pending)
            }
        }

        do {
            try await joinRequestStore.updateRequest(request, status: .approved)
            await joinRequestStore.refreshRequests(for: teamID)
        } catch {
            print("❌ JoinRequest update failed:", error)
        }
    }

    private func deny(_ request: JoinRequest) async {
        do {
            try await joinRequestStore.updateRequest(request, status: .denied)
            await joinRequestStore.refreshRequests(for: teamID)
        } catch {
            print("❌ JoinRequest update failed:", error)
        }
    }

    private func approveStatKeeper(_ request: StatKeeperRequest) {
        if let membership = membershipStore.membershipRecord(for: teamID, userID: request.requestedByUserID) {
            membershipStore.updateMembership(membership, status: .active, role: .statKeeper)
        }
        statKeeperRequestStore.updateRequest(request, status: .approved, reviewerID: roleManager.userID)
    }

    private func denyStatKeeper(_ request: StatKeeperRequest) {
        statKeeperRequestStore.updateRequest(request, status: .denied, reviewerID: roleManager.userID)
    }
}
