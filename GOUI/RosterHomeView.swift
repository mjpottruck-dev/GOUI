import SwiftUI

struct RosterHomeView: View {
    @Bindable var teamStore: TeamStore
    @State private var showingCreateTeam = false
    @State private var editingTeam: Team? = nil
    @State private var teamToDelete: Team? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GoStatsTheme.cardGap) {
                        if teamStore.teams.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "person.3")
                                    .font(.system(size: 28))
                                    .foregroundStyle(GoStatsTheme.emptyStateColor)
                                Text("No teams yet. Create your first team.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.emptyStateColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(teamStore.teams) { team in
                                Button { editingTeam = team } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(team.name)
                                                .font(.system(size: 17, weight: .medium))
                                                .foregroundStyle(GoStatsTheme.textPrimary)
                                            Text("\(team.players.count) players")
                                                .font(.system(size: 13))
                                                .foregroundStyle(GoStatsTheme.textMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                    }
                                    .padding(GoStatsTheme.cardPadding)
                                    .background(
                                        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                            .fill(Color.white)
                                            .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        teamToDelete = team
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        Button { showingCreateTeam = true } label: {
                            Text("Create Team")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                        .fill(GoStatsTheme.textPrimary)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, GoStatsTheme.cardMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Teams")
            .sheet(isPresented: $showingCreateTeam) {
                CreateTeamView(teamStore: teamStore) { _ in
                    showingCreateTeam = false
                }
            }
            .sheet(item: $editingTeam) { team in
                EditRosterView(team: team) { updated in
                    var merged = updated
                    if let current = teamStore.teams.first(where: { $0.id == team.id }) {
                        merged.matches = current.matches
                    }
                    teamStore.updateTeam(merged)
                }
            }
            .alert("Delete \(teamToDelete?.name ?? "Team")?", isPresented: Binding(
                get: { teamToDelete != nil },
                set: { if !$0 { teamToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let t = teamToDelete { teamStore.deleteTeam(t) }
                    teamToDelete = nil
                }
                Button("Cancel", role: .cancel) { teamToDelete = nil }
            } message: {
                Text("This will permanently delete the team and all its players. This cannot be undone.")
            }
        }
    }
}
