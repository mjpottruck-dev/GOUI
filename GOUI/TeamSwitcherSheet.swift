import SwiftUI

struct TeamSwitcherSheet: View {
    @Bindable var teamStore: TeamStore
    let onPick: (UUID) -> Void

    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var roleManager: RoleManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if activeTeams.isEmpty {
                    Text("No teams yet. Create or join a team first.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeTeams) { team in
                        Button {
                            onPick(team.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(team.name)
                                        .foregroundStyle(.primary)
                                    Text("\(SportCatalog.sport(for: team.sportID).displayName) • \(teamStore.activeSeason(for: team.id)?.name ?? "Season TBD")")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Switch Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var activeTeams: [Team] {
        let activeIDs = membershipStore.activeTeamIDs(for: roleManager.userID)
        let resolved = activeIDs.isEmpty ? teamStore.teams : teamStore.teams.filter { activeIDs.contains($0.id) }
        return resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
