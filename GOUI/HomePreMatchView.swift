import SwiftUI

struct HomePreMatchView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore

    @Binding var selectedTeamID: UUID?
    var onStartMatch: (UUID, GameTemplate?) -> Void

    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService

    @State private var selectedTemplateID: String? = nil
    @State private var selectedSeasonID: UUID? = nil
    @State private var showPermissionAlert = false
    @State private var showJoinTeam = false

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !activeTeams.isEmpty {
                        teamSwitcher
                    }

                    myTeamsSection

                    VStack(alignment: .leading, spacing: 10) {
                        Text("TEAM")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("Team", selection: Binding(
                            get: { selectedTeamID ?? activeTeams.first?.id },
                            set: { selectedTeamID = $0 }
                        )) {
                            ForEach(activeTeams) { team in
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
                        guard let teamID = selectedTeamID ?? activeTeams.first?.id else { return }
                        guard permissionService.canLogMatches(teamID: teamID) else {
                            showPermissionAlert = true
                            return
                        }
                        selectedTeamID = teamID
                        let template = GameTemplateCatalog.template(for: selectedTeam?.sportID ?? SportCatalog.defaultSportID, templateID: selectedTemplateID)
                        if var team = selectedTeam {
                            team.lastTemplateID = template?.id
                            teamStore.updateTeam(team)
                        }
                        onStartMatch(teamID, template)
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
                    .disabled(activeTeams.isEmpty || !permissionService.canLogMatches(teamID: selectedTeamID ?? activeTeams.first?.id ?? UUID()))

                    VStack(spacing: 10) {
                        NavigationLink {
                            RosterHomeView(teamStore: teamStore)
                        } label: {
                            rowButton(title: "Teams / Create Team", systemImage: "person.3")
                        }

                        NavigationLink {
                            if let teamID = selectedTeamID ?? activeTeams.first?.id {
                                TeamArchiveView(teamStore: teamStore, teamID: teamID)
                            } else {
                                Text("Select a team")
                            }
                        } label: {
                            rowButton(title: "Match Archive", systemImage: "clock.arrow.circlepath")
                        }

                        NavigationLink {
                            if let teamID = selectedTeamID ?? activeTeams.first?.id {
                                let sport = SportCatalog.sport(for: teamStore.teams.first(where: { $0.id == teamID })?.sportID)
                                StatsView(teamStore: teamStore, teamID: teamID, sport: sport)
                            } else {
                                Text("Select a team")
                            }
                        } label: {
                            rowButton(title: "Season Stats", systemImage: "chart.bar")
                        }

                        NavigationLink {
                            if let teamID = selectedTeamID ?? activeTeams.first?.id,
                               let team = teamStore.teams.first(where: { $0.id == teamID }) {
                                TeamStatsView(team: team, sport: SportCatalog.sport(for: team.sportID))
                            } else {
                                Text("Select a team")
                            }
                        } label: {
                            rowButton(title: "Player Stats", systemImage: "person.text.rectangle")
                        }

                        Button {
                            showJoinTeam = true
                        } label: {
                            rowButton(title: "Join Team by Code", systemImage: "person.crop.circle.badge.plus")
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
                selectedTeamID = activeTeams.first?.id
            }
            syncTemplateSelection()
            syncSeasonSelection()
        }
        .onChange(of: selectedTeamID) { _, _ in
            syncTemplateSelection()
            syncSeasonSelection()
        }
        .sheet(isPresented: $showJoinTeam) {
            JoinTeamByCodeView(teamStore: teamStore)
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coach access is required to start a match.")
        }
    }

    private var selectedTeam: Team? {
        guard let id = selectedTeamID ?? activeTeams.first?.id else { return nil }
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

    private var activeTeams: [Team] {
        let activeIDs = membershipStore.activeTeamIDs(for: roleManager.userID)
        let resolved = activeIDs.isEmpty ? teamStore.teams : teamStore.teams.filter { activeIDs.contains($0.id) }
        return resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var teamSwitcher: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("CURRENT TEAM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Picker("Current Team", selection: Binding(
                    get: { selectedTeamID ?? activeTeams.first?.id },
                    set: { selectedTeamID = $0 }
                )) {
                    ForEach(activeTeams) { team in
                        Text(team.name).tag(Optional(team.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var myTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MY TEAMS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.primary)

            if groupedTeams.isEmpty {
                LiquidGlassContainer(cornerRadius: 22) {
                    Text("No active teams yet.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(groupedTeams) { group in
                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(group.sport.displayName) • \(group.seasonLabel)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)
                            ForEach(group.teams) { team in
                                Button {
                                    selectedTeamID = team.id
                                } label: {
                                    HStack {
                                        Text(team.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(GoStatsTheme.text)
                                        Spacer()
                                        if selectedTeamID == team.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(GoStatsTheme.primary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var groupedTeams: [TeamGroup] {
        let groups = Dictionary(grouping: activeTeams) { team in
            let seasonLabel = teamStore.activeSeason(for: team.id)?.name ?? "Season TBD"
            return "\(team.sportID)|\(seasonLabel)"
        }

        return groups.compactMap { key, teams in
            guard let first = teams.first else { return nil }
            let seasonLabel = teamStore.activeSeason(for: first.id)?.name ?? "Season TBD"
            return TeamGroup(
                id: key,
                sport: SportCatalog.sport(for: first.sportID),
                seasonLabel: seasonLabel,
                teams: teams.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            )
        }
        .sorted { lhs, rhs in
            if lhs.sport.displayName == rhs.sport.displayName {
                return lhs.seasonLabel < rhs.seasonLabel
            }
            return lhs.sport.displayName < rhs.sport.displayName
        }
    }

    private func rowButton(title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct TeamGroup: Identifiable {
    let id: String
    let sport: any SportDefinition
    let seasonLabel: String
    let teams: [Team]
}
