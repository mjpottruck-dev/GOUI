import SwiftUI
import Observation

struct HomeView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?

    @State private var showingCreateTeam = false
    @State private var newTeamName: String = ""

    private var resolvedTeamID: UUID? {
        if let id = selectedTeamID { return id }
        return teamStore.teams.first?.id
    }

    private var resolvedTeamName: String {
        guard
            let tid = resolvedTeamID,
            let t = teamStore.teams.first(where: { $0.id == tid })
        else { return "My Team" }
        return t.name.isEmpty ? "My Team" : t.name
    }

    var body: some View {
        let _ = DebugRenderLogger.log("HomeView", enabled: DebugSettings.renderCountsEnabled)

        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // Header card (NO small + button)
                    LiquidGlassContainer(material: .thinMaterial) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("GoStats")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)

                                Text(resolvedTeamName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Start Match -> send user to Match tab pre-match flow
                    // (You said toolbar should only be visible AFTER you hit Start Match —
                    // we’ll keep match stuff inside the Match tab flow.)
                    NavigationLink {
                        HomePreMatchView(
                            store: store,
                            teamStore: teamStore,
                            selectedTeamID: $selectedTeamID,
                            onStartMatch: { teamID in
                                selectedTeamID = teamID
                            }
                        )
                    } label: {
                        primaryCard(
                            title: "Start Match",
                            subtitle: "Select a team, then open the match tracker",
                            icon: "play.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    // Archive
                    if let tid = resolvedTeamID {
                        NavigationLink {
                            TeamArchiveView(teamStore: teamStore, teamID: tid)
                        } label: {
                            primaryCard(
                                title: "Archive",
                                subtitle: "View saved matches",
                                icon: "archivebox.fill"
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    } else {
                        primaryCard(
                            title: "Archive",
                            subtitle: "Create a team first",
                            icon: "archivebox.fill"
                        )
                        .padding(.horizontal, 16)
                        .opacity(0.6)
                    }

                    // ✅ ONLY ONE Create New Team button (big one)
                    Button {
                        newTeamName = ""
                        showingCreateTeam = true
                    } label: {
                        Text("Create New Team")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(Color.teal)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    Spacer(minLength: 30)
                }
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            if selectedTeamID == nil {
                selectedTeamID = teamStore.teams.first?.id
            }
        }
        .sheet(isPresented: $showingCreateTeam) {
            createTeamSheet
        }
    }

    private var createTeamSheet: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                VStack(spacing: 14) {
                    Text("Create Team")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LiquidGlassContainer(material: .thinMaterial) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TEAM NAME")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)

                            TextField("e.g. Varsity", text: $newTeamName)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .foregroundStyle(GoStatsTheme.text)
                                .padding(.vertical, 6)
                        }
                    }

                    Spacer()

                    Button {
                        let name = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }

                        // Create + select the team
                        let team = Team(name: name)
                        teamStore.addTeam(team)
                        selectedTeamID = team.id

                        showingCreateTeam = false
                    } label: {
                        Text("Create")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.teal)
                            )
                    }
                    .padding(.bottom, 6)
                }
                .padding(16)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingCreateTeam = false }
                        .foregroundStyle(.red)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func primaryCard(title: String, subtitle: String, icon: String) -> some View {
        LiquidGlassContainer(material: .thinMaterial) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            }
            .padding(.vertical, 8)
        }
    }
}
