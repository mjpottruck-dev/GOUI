import SwiftUI

struct HomePreMatchView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore

    @Binding var selectedTeamID: UUID?
    var onStartMatch: (UUID, GameTemplate?) -> Void

    @EnvironmentObject var roleManager: RoleManager

    @State private var selectedTemplateID: String? = nil
    @State private var selectedSeasonID: UUID? = nil
    @State private var showPermissionAlert = false

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

                    if let team = selectedTeam {
                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SEASON")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                if seasons.isEmpty {
                                    Text("No seasons yet")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(GoStatsTheme.text2)
                                } else {
                                    Picker("Season", selection: Binding(
                                        get: { selectedSeasonID ?? seasons.first?.id },
                                        set: { newValue in
                                            selectedSeasonID = newValue
                                            if let newValue {
                                                teamStore.setActiveSeason(newValue, for: team.id)
                                            }
                                        }
                                    )) {
                                        ForEach(seasons) { season in
                                            Text(season.name).tag(Optional(season.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }

                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("GAME TEMPLATE")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                if templates.isEmpty {
                                    Text("Default match settings")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(GoStatsTheme.text2)
                                } else {
                                    Picker("Template", selection: Binding(
                                        get: { selectedTemplateID ?? templates.first?.id },
                                        set: { selectedTemplateID = $0 }
                                    )) {
                                        ForEach(templates) { template in
                                            Text(template.name).tag(Optional(template.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }
                    }

                    Button {
                        guard roleManager.canLogGames() else {
                            showPermissionAlert = true
                            return
                        }
                        guard let tid = selectedTeamID ?? teamStore.teams.first?.id else { return }
                        selectedTeamID = tid
                        let template = GameTemplateCatalog.template(for: selectedTeam?.sportID ?? SportCatalog.defaultSportID, templateID: selectedTemplateID)
                        if var team = selectedTeam {
                            team.lastTemplateID = template?.id
                            teamStore.updateTeam(team)
                        }
                        onStartMatch(tid, template)
                    } label: {
                        Text(startMatchLabel)
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
                    .disabled(teamStore.teams.isEmpty || !roleManager.canLogGames())

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
            syncTemplateSelection()
            syncSeasonSelection()
        }
        .onChange(of: selectedTeamID) { _, _ in
            syncTemplateSelection()
            syncSeasonSelection()
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coach access is required to start a match.")
        }
    }

    private var selectedTeam: Team? {
        guard let id = selectedTeamID ?? teamStore.teams.first?.id else { return nil }
        return teamStore.teams.first(where: { $0.id == id })
    }

    private var templates: [GameTemplate] {
        guard let team = selectedTeam else { return [] }
        return GameTemplateCatalog.templates(for: team.sportID)
    }

    private var seasons: [Season] {
        guard let team = selectedTeam else { return [] }
        return teamStore.seasons(for: team.id)
    }

    private func syncTemplateSelection() {
        guard let team = selectedTeam else {
            selectedTemplateID = nil
            return
        }
        selectedTemplateID = team.lastTemplateID ?? GameTemplateCatalog.defaultTemplate(for: team.sportID)?.id
    }

    private func syncSeasonSelection() {
        guard let team = selectedTeam else {
            selectedSeasonID = nil
            return
        }
        let resolved = teamStore.activeSeasonID(for: team.id) ?? seasons.first?.id
        selectedSeasonID = resolved
        if let resolved {
            teamStore.setActiveSeason(resolved, for: team.id)
        }
    }

    private var startMatchLabel: String {
        guard let team = selectedTeam else { return "Start Match" }
        return isMeetSport(sportID: team.sportID) ? "Start Meet" : "Start Match"
    }

    private func isMeetSport(sportID: String) -> Bool {
        switch sportID {
        case SportCatalog.swimmingID,
             SportCatalog.trackID,
             SportCatalog.crossCountryID,
             SportCatalog.golfID:
            return true
        default:
            return false
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
