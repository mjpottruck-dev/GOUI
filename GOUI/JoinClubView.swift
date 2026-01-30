import SwiftUI

struct JoinClubView: View {
    @EnvironmentObject var clubStore: ClubStore
    @EnvironmentObject var roleManager: RoleManager

    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode: String = ""
    @State private var statusMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Invite Code") {
                    TextField("Enter code", text: $inviteCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Join Club") {
                        handleJoin()
                    }
                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Join Club")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func handleJoin() {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }
        if roleManager.profile == nil {
            roleManager.setRole(.parentPlayer)
        }
        guard let profile = roleManager.profile else { return }
        if let result = clubStore.joinClub(with: code, userID: profile.id) {
            roleManager.setRole(result.role)
            roleManager.updateClub(result.club.id)
            statusMessage = "Joined \(result.club.name)."
        } else {
            statusMessage = "Invite code not recognized."
        }
    }
}
