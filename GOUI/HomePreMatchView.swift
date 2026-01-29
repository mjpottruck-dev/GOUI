import SwiftUI

struct HomePreMatchView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore

    @Binding var selectedTeamID: UUID?
    var onStartMatch: (UUID) -> Void

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TEAM")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("Team", selection: Binding(
                            get: { selectedTeamID ?? teamStore.teams.first?.id },
                            set: { selectedTeamID = $0 }
                        )) {
                            ForEach(teamStore.teams) { team in
                                Text(team.name).tag(Optional(team.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )

                    Button {
                        guard let tid = selectedTeamID ?? teamStore.teams.first?.id else { return }
                        selectedTeamID = tid
                        onStartMatch(tid)
                    } label: {
                        Text("Start Match")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(GoStatsTheme.primary.opacity(0.95))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(teamStore.teams.isEmpty)

                    VStack(spacing: 10) {
                        NavigationLink {
                            RosterHomeView(teamStore: teamStore)
                        } label: {
                            rowButton(title: "Teams / Create Team", systemImage: "person.3")
                        }

                        NavigationLink {
                            if let teamID = selectedTeamID ?? teamStore.teams.first?.id {
                                TeamArchiveView(teamStore: teamStore, teamID: teamID)
                            } else {
                                Text("Select a team")
                            }
                        } label: {
                            rowButton(title: "Match Archive", systemImage: "clock.arrow.circlepath")
                        }

                        NavigationLink {
                            if let teamID = selectedTeamID ?? teamStore.teams.first?.id {
                                let sport = SportCatalog.sport(for: teamStore.teams.first(where: { $0.id == teamID })?.sportID)
                                StatsView(teamStore: teamStore, teamID: teamID, sport: sport)
                            } else {
                                Text("Select a team")
                            }
                        } label: {
                            rowButton(title: "Season Stats", systemImage: "chart.bar")
                        }

                        NavigationLink {
                            if let teamID = selectedTeamID ?? teamStore.teams.first?.id,
                               let team = teamStore.teams.first(where: { $0.id == teamID }) {
                                TeamStatsView(team: team, sport: SportCatalog.sport(for: team.sportID))
                            } else {
                                Text("Select a team")
                            }
                        } label: {
                            rowButton(title: "Player Stats", systemImage: "person.text.rectangle")
                        }
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 30)
                }
                .padding(16)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedTeamID == nil {
                selectedTeamID = teamStore.teams.first?.id
            }
        }
    }

    private func rowButton(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 26)
                .foregroundStyle(GoStatsTheme.primary)

            Text(title)
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .foregroundStyle(Color.primary)
    }
}
