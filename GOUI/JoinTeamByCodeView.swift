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
    @State private var message: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Join Team") {
                    TextField("Enter team code", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    TextField("Message (optional)", text: $message)

                    Button("Request Access") {
                        Task { await handleJoin() }
                    }

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
        let requesterUser = authManager.currentUser
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

        guard roleManager.role != .recruiter else {
            statusMessage = "Recruiters cannot join teams by code."
            return
        }

        let defaultMemberType: TeamMemberType = {
            switch roleManager.role {
            case .coach:
                return .coach
            case .parent:
                return .parent
            case .athlete:
                return .athlete
            case .recruiter:
                return .recruiterViewer
            }
        }()
        let defaultPermission: TeamPermissionRole = roleManager.role == .coach ? .coachStaff : .viewer
        if joinRequestStore.hasPendingRequest(teamID: team.id, userID: requesterUser?.userID ?? roleManager.userID) {
            statusMessage = "You already requested to join this team."
            return
        }

        if team.requiresApprovalToJoin {
            let request = JoinRequest(
                teamID: team.id,
                teamName: team.name,
                joinCode: team.joinCode,
                requesterUserID: requesterUser?.userID ?? roleManager.userID,
                requesterName: roleManager.displayName,
                requesterUserRecordName: requesterUser?.userRecordName,
                requestedMemberType: defaultMemberType,
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            do {
                try await joinRequestStore.submitJoinRequest(request)
                statusMessage = "Request sent to \(team.name)."
            } catch {
                statusMessage = "Could not send request. Try again."
            }
        } else {
            let requesterID = requesterUser?.userID ?? roleManager.userID
            membershipStore.requestJoin(teamID: team.id, userID: requesterID, memberType: defaultMemberType, permissionRole: defaultPermission)
            if let pending = membershipStore.membershipRecord(for: team.id, userID: requesterID) {
                membershipStore.approveMembership(pending)
            }
            if let shareRecordName = team.shareRecordName, let requesterRecordName = requesterUser?.userRecordName {
                let permission: CKShare.ParticipantPermission = defaultPermission.hasCoachPermissions ? .readWrite : .readOnly
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
