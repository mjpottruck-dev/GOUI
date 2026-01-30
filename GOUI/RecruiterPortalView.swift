import SwiftUI

struct RecruiterPortalView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var roleManager: RoleManager

    @State private var searchText: String = ""
    @State private var selectedSportID: String? = nil
    @State private var selectedTeamID: UUID? = nil
    @State private var selectedSeasonID: UUID? = nil
    @State private var gradYearText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                if !authManager.isSignedIn {
                    Text("Sign in with Apple to access recruiter profiles.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .multilineTextAlignment(.center)
                        .padding(24)
                } else if roleManager.role != .recruiter {
                    Text("Recruiter accounts only. Update your role in settings.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .multilineTextAlignment(.center)
                        .padding(24)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            filterCard

                            ForEach(filteredPlayers) { entry in
                                NavigationLink {
                                    RecruiterPlayerProfileView(entry: entry, clipStore: clipStore)
                                } label: {
                                    playerCard(entry)
                                }
                                .buttonStyle(.plain)
                            }

                            if filteredPlayers.isEmpty {
                                LiquidGlassContainer(cornerRadius: 22) {
                                    Text("No recruiter-visible players found.")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationTitle("Recruiter Portal")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search players")
        }
    }

    private var filterCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SEARCH FILTERS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                Picker("Sport", selection: $selectedSportID) {
                    Text("All Sports").tag(String?.none)
                    ForEach(SportCatalog.all, id: \.id) { sport in
                        Text(sport.displayName).tag(Optional(sport.id))
                    }
                }
                .pickerStyle(.menu)

                Picker("Team", selection: $selectedTeamID) {
                    Text("All Teams").tag(UUID?.none)
                    ForEach(teamStore.teams) { team in
                        Text(team.name).tag(Optional(team.id))
                    }
                }
                .pickerStyle(.menu)

                Picker("Season", selection: $selectedSeasonID) {
                    Text("All Seasons").tag(UUID?.none)
                    ForEach(seasonOptions) { season in
                        Text(season.name).tag(Optional(season.id))
                    }
                }
                .pickerStyle(.menu)

                TextField("Grad Year", text: $gradYearText)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var seasonOptions: [Season] {
        let seasons = teamStore.seasons
        if let selectedTeamID {
            return seasons.filter { $0.teamID == selectedTeamID }
        }
        return seasons
    }

    private var filteredPlayers: [RecruiterPlayerEntry] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let gradYear = Int(gradYearText.trimmingCharacters(in: .whitespacesAndNewlines))

        let entries = teamStore.teams.flatMap { team -> [RecruiterPlayerEntry] in
            let sport = SportCatalog.sport(for: team.sportID)
            return team.players.map { player in
                RecruiterPlayerEntry(player: player, team: team, sport: sport)
            }
        }

        return entries.filter { entry in
            guard entry.player.profile.isRecruiterVisible else { return false }
            if !trimmedSearch.isEmpty && !entry.player.name.lowercased().contains(trimmedSearch) {
                return false
            }
            if let selectedSportID, entry.team.sportID != selectedSportID {
                return false
            }
            if let selectedTeamID, entry.team.id != selectedTeamID {
                return false
            }
            if let selectedSeasonID,
               !teamStore.seasons(for: entry.team.id).contains(where: { $0.id == selectedSeasonID }) {
                return false
            }
            if let gradYear, entry.player.profile.gradYear != gradYear {
                return false
            }
            return true
        }
    }

    private func playerCard(_ entry: RecruiterPlayerEntry) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("#\(entry.player.number) \(entry.player.name)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text("\(entry.team.name) • \(entry.sport.displayName)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
                Text(entry.player.profile.gradYear.map { "Grad '\($0)" } ?? "Grad year TBD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }
}

struct RecruiterPlayerProfileView: View {
    let entry: RecruiterPlayerEntry
    @ObservedObject var clipStore: ClipStore
    @EnvironmentObject var authManager: AuthManager

    @State private var contactMessage: String? = nil
    @State private var contactTaskActive = false
    private let contactService = RecruiterContactService()

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    headerCard
                    bioCard
                    statsCard
                    highlightsCard
                    teamCard
                    contactCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Player Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("#\(entry.player.number) \(entry.player.name)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text("\(entry.team.name) • \(entry.sport.displayName)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private var bioCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("BIO")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                Text(entry.player.profile.bio.isEmpty ? "No bio provided yet." : entry.player.profile.bio)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text2)
                HStack(spacing: 12) {
                    infoPill(label: "Grad", value: entry.player.profile.gradYear.map(String.init) ?? "TBD")
                    infoPill(label: "Height", value: entry.player.profile.height.isEmpty ? "-" : entry.player.profile.height)
                    infoPill(label: "Weight", value: entry.player.profile.weight.isEmpty ? "-" : entry.player.profile.weight)
                }
            }
        }
    }

    private var statsCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SEASON STATS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                if entry.player.profile.statsHistory.isEmpty {
                    Text("No stats history added yet.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    ForEach(entry.player.profile.statsHistory) { snapshot in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.seasonLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text)
                            Text(snapshotSummary(snapshot))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }
                }
            }
        }
    }

    private var highlightsCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HIGHLIGHTS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                if highlightClips.isEmpty {
                    Text("No highlights yet.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    ForEach(highlightClips) { clip in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(clip.title.isEmpty ? "Highlight" : clip.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text)
                            Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }
                }
            }
        }
    }

    private var teamCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TEAM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                Text(entry.team.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text("\(entry.team.players.count) players • \(entry.team.matches.count) matches")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text2)
                NavigationLink("View Team") {
                    RecruiterTeamView(team: entry.team, sport: entry.sport)
                }
                .font(.system(size: 13, weight: .semibold))
            }
        }
    }

    private var contactCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("REQUEST CONTACT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                Text("Send a message request to the team manager. No email or SMS is sent yet.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text2)
                Button {
                    Task { await sendContactRequest() }
                } label: {
                    Text(contactTaskActive ? "Sending..." : "Request Contact")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(contactTaskActive || authManager.currentUser == nil)

                if let contactMessage {
                    Text(contactMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private func sendContactRequest() async {
        guard let recruiter = authManager.currentUser else {
            contactMessage = "Sign in to send a request."
            return
        }
        contactTaskActive = true
        defer { contactTaskActive = false }
        do {
            try await contactService.sendContactRequest(
                teamID: entry.team.id,
                playerID: entry.player.id,
                recruiterUserID: recruiter.userID
            )
            contactMessage = "Request sent."
        } catch {
            contactMessage = "Could not send request."
        }
    }

    private var highlightClips: [Clip] {
        let ids = Set(entry.player.profile.highlightClipIDs)
        return clipStore.clips.filter { ids.contains($0.id) }
    }

    private func infoPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private func snapshotSummary(_ snapshot: PlayerSeasonSnapshot) -> String {
        if snapshot.statSummary.isEmpty {
            return "No stats recorded"
        }
        return snapshot.statSummary.map { key, value in "\(key): \(value)" }.sorted().joined(separator: " • ")
    }
}

struct RecruiterPlayerEntry: Identifiable {
    let player: Player
    let team: Team
    let sport: any SportDefinition

    var id: UUID { player.id }
}

struct RecruiterTeamView: View {
    let team: Team
    let sport: any SportDefinition

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(team.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text)
                            Text("\(sport.displayName) • \(team.players.count) players")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }

                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ROSTER")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.primary)
                            ForEach(team.players) { player in
                                Text("#\(player.number) \(player.name)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.text)
                            }
                        }
                    }

                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SCHEDULE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.primary)
                            if team.matches.isEmpty {
                                Text("No matches scheduled.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.text2)
                            } else {
                                ForEach(team.matches.prefix(5)) { match in
                                    Text("\(match.date.formatted(date: .abbreviated, time: .omitted)) • \(match.opponent)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(GoStatsTheme.text)
                                }
                            }
                        }
                    }

                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BASIC STATS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.primary)
                            Text("Matches: \(team.matches.count)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(GoStatsTheme.text)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
    }
}
