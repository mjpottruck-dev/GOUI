import SwiftUI

struct JoinTeamByCodeView: View {
    @Bindable var teamStore: TeamStore

    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var roleManager: RoleManager
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
                        handleJoin()
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

    private func handleJoin() {
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }
        guard let team = teamStore.teams.first(where: { $0.joinCode == code }) else {
            statusMessage = "Team code not recognized."
            return
        }

        if membershipStore.membershipRecord(for: team.id, userID: roleManager.userID) != nil {
            statusMessage = "You already requested or joined this team."
            return
        }

        let defaultRole: TeamMembershipRole = roleManager.role == .coach ? .coachStaff : .viewer
        membershipStore.requestJoin(teamID: team.id, userID: roleManager.userID, role: defaultRole)
        statusMessage = "Request sent to \(team.name)."
    }
}
