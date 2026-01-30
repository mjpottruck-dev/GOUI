import SwiftUI

struct ScheduleView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var showSwitcher = false
    @EnvironmentObject var appState: AppState

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        NavigationStack {
            List {
                if let team {
                    Section("Scheduled Events") {
                        ForEach(team.matches) { match in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.title.isEmpty ? "Game vs \(match.opponent)" : match.title)
                                    .font(.headline)
                                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if team.matches.isEmpty {
                            Text("No games, practices, or events scheduled yet.")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Select a team to see games, practices, and events.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSwitcher = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showSwitcher) {
                TeamSwitcherSheet(teamStore: teamStore) { picked in
                    appState.currentTeamID = picked
                }
            }
        }
    }
}
