import SwiftUI

struct TeamSettingsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var permissionService: PermissionService

    @State private var showTransfer = false
    @State private var selectedNewManager: TeamMembership?

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        Form {
            Section("Team") {
                if let team {
                    Text("Join Code: \(team.joinCode)")
                    Toggle("Require Approval to Join", isOn: Binding(
                        get: { team.requiresApprovalToJoin },
                        set: { newValue in
                            var updated = team
                            updated.requiresApprovalToJoin = newValue
                            teamStore.updateTeam(updated)
                        }
                    ))
                }
            }

            Section("Ownership") {
                Button("Transfer Ownership") {
                    showTransfer = true
                }
                .disabled(!permissionService.canManageMembers(teamID: teamID))
            }
        }
        .navigationTitle("Team Settings")
        .sheet(isPresented: $showTransfer) {
            NavigationStack {
                List {
                    ForEach(membershipStore.memberships(for: teamID).filter { $0.status == .active }) { membership in
                        Button {
                            selectedNewManager = membership
                        } label: {
                            HStack {
                                Text(membership.userID)
                                Spacer()
                                if selectedNewManager?.id == membership.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(GoStatsTheme.primary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select New Manager")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showTransfer = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Transfer") {
                            transferOwnership()
                            showTransfer = false
                        }
                        .disabled(selectedNewManager == nil)
                    }
                }
            }
        }
    }

    private func transferOwnership() {
        guard var team, let newManager = selectedNewManager else { return }
        let oldManagerID = team.managerUserID
        team.managerUserID = newManager.userID
        teamStore.updateTeam(team)

        if let newManagerMembership = membershipStore.membershipRecord(for: teamID, userID: newManager.userID) {
            membershipStore.updateMembership(newManagerMembership, role: .manager, memberType: .coach)
        }

        if let oldManagerID, let oldMembership = membershipStore.membershipRecord(for: teamID, userID: oldManagerID) {
            membershipStore.updateMembership(oldMembership, role: .coachManager, memberType: .coach)
        }
    }
}
