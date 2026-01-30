import CloudKit
import SwiftUI

struct JoinTeamByCodeView: View {
    @Bindable var teamStore: TeamStore

    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var joinRequestStore: JoinRequestStore
    @EnvironmentObject var sharingService: SharingService
    @Environment(\.dismiss) private var dismiss

    @State private var joinCode: String = ""
    @State private var statusMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Join Team") {
                    TextField("Enter team code", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button("Request Access") {
                        Task { await handleJoin() }
                    }
                    .disabled(!authManager.isSignedIn)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Join Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func handleJoin() async {
        guard let authUser = authManager.currentUser else {
            statusMessage = "Sign in with Apple to request access."
            return
        }
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }
        guard let team = teamStore.teams.first(where: { $0.joinCode == code }) else {
            statusMessage = "Team code not recognized."
            return
        }

        await joinRequestStore.refreshRequests(for: team.id)
        if membershipStore.membershipRecord(for: team.id, userID: roleManager.userID) != nil {
            statusMessage = "You already requested or joined this team."
            return
        }

        let defaultRole: TeamMembershipRole = roleManager.role == .coach ? .coachStaff : .viewer
        if joinRequestStore.hasPendingRequest(teamID: team.id, userID: authUser.userID) {
            statusMessage = "You already requested to join this team."
            return
        }

        if team.requiresApprovalToJoin {
            let request = JoinRequest(
                teamID: team.id,
                teamName: team.name,
                joinCode: team.joinCode,
                requesterUserID: authUser.userID,
                requesterUserRecordName: authUser.userRecordName,
                requestedRole: defaultRole
            )
            do {
                try await joinRequestStore.submitJoinRequest(request)
                statusMessage = "Request sent to \(team.name)."
            } catch {
                statusMessage = "Could not send request. Try again."
            }
        } else {
            membershipStore.requestJoin(teamID: team.id, userID: authUser.userID, role: defaultRole)
            if let pending = membershipStore.membershipRecord(for: team.id, userID: authUser.userID) {
                membershipStore.approveMembership(pending)
            }
            if let shareRecordName = team.shareRecordName, let requesterRecordName = authUser.userRecordName {
                let permission: CKShare.ParticipantPermission = defaultRole.hasCoachPermissions ? .readWrite : .readOnly
                try? await sharingService.addParticipant(
                    shareRecordName: shareRecordName,
                    userRecordName: requesterRecordName,
                    permission: permission
                )
            }
            statusMessage = "You're in! Access granted to \(team.name)."
        }
    }
}
