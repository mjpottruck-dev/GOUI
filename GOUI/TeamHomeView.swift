import SwiftUI

struct TeamHomeView: View {
    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    @Binding var selectedTeamID: UUID?

    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var membershipStore: TeamMembershipStore

    @State private var showTeamSwitcher = false
    @State private var showCreateTeam = false
    @State private var showJoinTeam = false

    var body: some View {
        NavigationStack {
            if roleManager.role == .athlete {
                athleteHome
            } else {
                coachHome
            }
        }
        .sheet(isPresented: $showTeamSwitcher) {
            TeamSwitcherSheet(teamStore: teamStore) { picked in
                selectedTeamID = picked
            }
        }
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamView(teamStore: teamStore) { teamID in
                selectedTeamID = teamID
            }
        }
        .sheet(isPresented: $showJoinTeam) {
            JoinTeamByCodeView(teamStore: teamStore)
        }
        .onAppear {
            if selectedTeamID == nil {
                selectedTeamID = activeTeams.first?.id
            }
        }
    }

    private var coachHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                teamSwitcher

                myTeamsSection

                HStack(spacing: 12) {
                    Button {
                        showCreateTeam = true
                    } label: {
                        Label("Create Team", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showJoinTeam = true
                    } label: {
                        Label("Join Team", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                NavigationLink("Go to Match Setup") {
                    HomePreMatchView(
                        store: store,
                        teamStore: teamStore,
                        selectedTeamID: $selectedTeamID
                    ) { teamID, _ in
                        selectedTeamID = teamID
                    }
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 16)
            }
            .padding(16)
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTeamSwitcher = true
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private var athleteHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                athleteTeamsSection

                upcomingCard

                athleteStatsOverview

                athleteQuickLinks

                playerIDCard

                Spacer(minLength: 16)
            }
            .padding(16)
        }
        .navigationTitle("Home")
    }

    private var activeTeams: [Team] {
        let activeIDs = membershipStore.activeTeamIDs(for: roleManager.userID)
        let resolved = activeIDs.isEmpty ? teamStore.teams : teamStore.teams.filter { activeIDs.contains($0.id) }
        return resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var activeTeam: Team? {
        let fallback = activeTeams.first
        guard let selectedTeamID else { return fallback }
        return activeTeams.first(where: { $0.id == selectedTeamID }) ?? fallback
    }

    private var activeSport: any SportDefinition {
        SportCatalog.sport(for: activeTeam?.sportID)
    }

    private var athleteTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Teams")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                Spacer()

                Button {
                    showTeamSwitcher = true
                } label: {
                    Label("Switch", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
            }

            if activeTeams.isEmpty {
                LiquidGlassContainer(cornerRadius: 22) {
                    Text("No active teams yet.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(activeTeams) { team in
                    LiquidGlassContainer(cornerRadius: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)
                                Text(SportCatalog.sport(for: team.sportID).displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                            Spacer()
                            if team.id == selectedTeamID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(GoStatsTheme.primary)
                            }
                        }
                    }
                    .onTapGesture { selectedTeamID = team.id }
                }
            }

            Button {
                showJoinTeam = true
            } label: {
                Label("Join Team", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var upcomingCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("NEXT GAME / PRACTICE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                if let upcomingMatch = nextUpcomingMatch, let team = activeTeam {
                    Text(upcomingMatch.title.isEmpty ? "Game vs \(upcomingMatch.opponent)" : upcomingMatch.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)

                    Text("\(team.name) • \(upcomingMatch.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 13))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    Text("No upcoming events yet. Your coach will add games and practices here.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private var athleteStatsOverview: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("MY STATS OVERVIEW")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                if let summary = athleteSummary {
                    HStack(spacing: 10) {
                        ForEach(summary.items, id: \.label) { item in
                            statChip(item.label, item.value)
                        }
                    }
                } else {
                    Text("Link your roster spot to see personal stats at a glance.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private var athleteQuickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATS + ARCHIVE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.primary)

            if let team = activeTeam {
                NavigationLink {
                    StatsView(teamStore: teamStore, teamID: team.id, sport: activeSport)
                } label: {
                    homeLinkRow(title: "Season Stats", subtitle: "Wins, losses, scoring, and leaders", icon: "chart.bar")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeamStatsView(team: team, sport: activeSport)
                } label: {
                    homeLinkRow(title: "Player Stats", subtitle: "Full stats for every teammate", icon: "person.text.rectangle")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeamArchiveView(teamStore: teamStore, teamID: team.id)
                } label: {
                    homeLinkRow(title: "Match Archive", subtitle: "Past games, stats, and video", icon: "archivebox.fill")
                }
                .buttonStyle(.plain)
            } else {
                LiquidGlassContainer(cornerRadius: 22) {
                    Text("Join a team to unlock stats and archived matches.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private var playerIDCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("PLAYER ID")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
                Text(roleManager.userID)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GoStatsTheme.text)
                Text("Share this ID with recruiters to find your profile faster.")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private func homeLinkRow(title: String, subtitle: String, icon: String) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private var nextUpcomingMatch: MatchRecord? {
        guard let team = activeTeam else { return nil }
        let now = Date()
        return team.matches
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
            .first
    }

    private struct AthleteSummary {
        let items: [(label: String, value: String)]
    }

    private var athleteSummary: AthleteSummary? {
        guard let team = activeTeam else { return nil }
        guard let player = team.players.first(where: { $0.name.localizedCaseInsensitiveCompare(roleManager.displayName) == .orderedSame }) else {
            return nil
        }

        let totals = aggregateStats(for: player.id, matches: team.matches, sport: activeSport)
        let primaryStat = activeSport.statSchema.first { $0.id == activeSport.scoringRules.primaryStatID }
            ?? StatType(
                id: activeSport.scoringRules.primaryStatID,
                displayName: activeSport.scoringRules.scoreLabel,
                shortLabel: nil,
                countsForTeam: true,
                countsForPlayer: true
            )

        let assistsStat = activeSport.statSchema.first { $0.id == "assists" }
        let primaryLabel = primaryStat.shortLabel ?? primaryStat.displayName
        var items: [(String, String)] = [
            (primaryLabel, "\(totals.statTotals[primaryStat.id, default: 0])")
        ]

        if let assistsStat {
            items.append((assistsStat.shortLabel ?? assistsStat.displayName, "\(totals.statTotals[assistsStat.id, default: 0])"))
        } else if totals.secondsPlayed > 0 {
            items.append(("Minutes", "\(totals.secondsPlayed / 60)"))
        }

        items.append(("Games", "\(totals.gamesPlayed)"))
        return AthleteSummary(items: items)
    }

    private struct AthleteAggregate {
        let statTotals: [String: Int]
        let gamesPlayed: Int
        let secondsPlayed: Int
    }

    private func aggregateStats(for playerID: UUID, matches: [MatchRecord], sport: any SportDefinition) -> AthleteAggregate {
        var totals: [String: Int] = [:]
        var gamesPlayed = 0
        var secondsPlayed = 0

        for match in matches {
            if let line = match.playerStats[playerID] {
                gamesPlayed += 1
                for stat in sport.statSchema where stat.countsForPlayer {
                    let value = line.value(for: stat.id)
                    if value > 0 {
                        totals[stat.id, default: 0] += value
                    }
                }
            }
            secondsPlayed += match.playerSeconds[playerID] ?? 0
        }

        return AthleteAggregate(statTotals: totals, gamesPlayed: gamesPlayed, secondsPlayed: secondsPlayed)
    }

    private var teamSwitcher: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Team")
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
        }
    }

    private var myTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Teams")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.primary)

            if activeTeams.isEmpty {
                LiquidGlassContainer(cornerRadius: 22) {
                    Text("No active teams yet.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(activeTeams) { team in
                    LiquidGlassContainer(cornerRadius: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)
                                Text(SportCatalog.sport(for: team.sportID).displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                            Spacer()
                            if team.id == selectedTeamID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(GoStatsTheme.primary)
                            }
                        }
                    }
                    .onTapGesture { selectedTeamID = team.id }
                }
            }
        }
    }
}
