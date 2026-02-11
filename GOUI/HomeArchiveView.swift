import SwiftUI

struct HomeArchiveView: View {

    @State var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?

    let onStartMatch: () -> Void

    @State private var pendingDelete: MatchRecord? = nil
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    headerCard

                    archiveCard

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("GoStats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if selectedTeamID == nil {
                selectedTeamID = teamStore.teams.first?.id
            }
        }
        .confirmationDialog(
            "Delete Match?",
            isPresented: $showDeleteConfirm,
            presenting: pendingDelete
        ) { match in
            Button("Delete", role: .destructive) {
                delete(match)
            }
            Button("Cancel", role: .cancel) { }
        } message: { match in
            Text("This will permanently remove \(match.opponent.isEmpty ? "this match" : "the match vs \(match.opponent)") from your archive.")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TEAM")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)

                    Spacer()

                    if let team = selectedTeam {
                        Text("\(team.players.count) players")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                teamPicker

                Button {
                    GoStatsTheme.hapticTap()
                    onStartMatch()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Match")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(GoStatsTheme.teal)
                    )
                }
                .buttonStyle(PressableScale())
            }
        }
    }

    private var teamPicker: some View {
        Group {
            if teamStore.teams.isEmpty {
                Text("No teams yet.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            } else {
                Picker("Team", selection: Binding(
                    get: { selectedTeamID ?? teamStore.teams.first!.id },
                    set: { selectedTeamID = $0 }
                )) {
                    ForEach(teamStore.teams, id: \.id) { t in
                        Text(t.name).tag(t.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(GoStatsTheme.teal)
            }
        }
    }

    // MARK: - Archive

    private var archiveCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("ARCHIVE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)

                    Spacer()

                    Text("\(selectedTeam?.matches.count ?? 0)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rChip, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
                        )
                }

                if let team = selectedTeam, !team.matches.isEmpty {

                    List {
                        ForEach(team.matches) { m in
                            NavigationLink {
                                MatchDetailView(match: m, team: team)
                            } label: {
                                matchRow(match: m)
                                    .contentShape(Rectangle())
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    GoStatsTheme.hapticTap()
                                    pendingDelete = m
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    .frame(height: CGFloat(min(team.matches.count, 8)) * 66.0 + 12)
                    .background(Color.clear)

                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)

                        Text("No saved matches yet. End a match to save it here.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func matchRow(match: MatchRecord) -> some View {
        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text(primaryMatchLabel(match))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }

            Spacer()

            Text("\(match.goalsFor)–\(match.goalsAgainst)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.50))
        )
    }

    private func primaryMatchLabel(_ match: MatchRecord) -> String {
        if !match.opponent.isEmpty {
            return match.opponent
        }
        if !match.title.isEmpty {
            return match.title
        }
        return "Meet"
    }

    private func delete(_ match: MatchRecord) {
        guard let tid = selectedTeamID else { return }
        teamStore.deleteMatch(teamID: tid, matchID: match.id)
        pendingDelete = nil
    }

    // MARK: - Derived

    private var selectedTeam: Team? {
        guard let id = selectedTeamID else { return teamStore.teams.first }
        return teamStore.teams.first(where: { $0.id == id })
    }
}

