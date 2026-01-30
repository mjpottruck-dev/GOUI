import SwiftUI

struct PlayerProfilesView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @ObservedObject var clipStore: ClipStore

    @State private var selectedPlayer: Player? = nil

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    if let team, team.players.isEmpty {
                        emptyState
                    } else {
                        ForEach(team?.players ?? []) { player in
                            Button {
                                selectedPlayer = player
                            } label: {
                                playerRow(player)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Recruiting Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPlayer) { player in
            PlayerProfileEditorView(
                player: player,
                teamStore: teamStore,
                teamID: teamID,
                clipStore: clipStore
            ) { updated in
                teamStore.updatePlayer(updated, on: teamID)
            }
        }
    }

    private var emptyState: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("No players yet")
                    .font(.headline)
                Text("Add players to build recruiting profiles.")
                    .font(.subheadline)
                    .foregroundStyle(GoStatsTheme.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func playerRow(_ player: Player) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("#\(player.number) \(player.name)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text)
                    Text(profileStatus(player.profile))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(GoStatsTheme.text2)
            }
            .padding(.vertical, 6)
        }
    }

    private func profileStatus(_ profile: PlayerProfile) -> String {
        let visibility = profile.isPublic ? "Public" : "Private"
        let recruiter = profile.isRecruiterVisible ? "Recruiter-visible" : "Recruiter-hidden"
        let grad = profile.gradYear.map { "'\($0)" } ?? "Grad year TBD"
        return "\(visibility) • \(recruiter) • \(grad)"
    }
}

struct PlayerProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var profile: PlayerProfile
    @State private var bio: String
    @State private var height: String
    @State private var weight: String
    @State private var gradYear: String
    @State private var gpa: String
    @State private var positions: String
    @State private var primarySports: String
    @State private var region: String
    @State private var showShareSheet = false

    let playerID: UUID
    let playerName: String
    let playerNumber: Int
    let teamStore: TeamStore
    let teamID: UUID
    @ObservedObject var clipStore: ClipStore
    let onSave: (Player) -> Void

    init(player: Player, teamStore: TeamStore, teamID: UUID, clipStore: ClipStore, onSave: @escaping (Player) -> Void) {
        self._profile = State(initialValue: player.profile)
        self._bio = State(initialValue: player.profile.bio)
        self._height = State(initialValue: player.profile.height)
        self._weight = State(initialValue: player.profile.weight)
        self._gradYear = State(initialValue: player.profile.gradYear.map { String($0) } ?? "")
        self._gpa = State(initialValue: player.profile.gpa.map { String(format: "%.2f", $0) } ?? "")
        self._positions = State(initialValue: player.profile.positions.joined(separator: ", "))
        self._primarySports = State(initialValue: player.profile.primarySports.joined(separator: ", "))
        self._region = State(initialValue: player.profile.region)
        self.playerID = player.id
        self.playerName = player.name
        self.playerNumber = player.number
        self.teamStore = teamStore
        self.teamID = teamID
        self.clipStore = clipStore
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    Text("#\(playerNumber) \(playerName)")
                        .font(.headline)
                }

                Section("Bio") {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Height (e.g. 6'2\")", text: $height)
                    TextField("Weight (e.g. 185 lbs)", text: $weight)
                }

                Section("Academics") {
                    TextField("Grad Year", text: $gradYear)
                        .keyboardType(.numberPad)
                    TextField("GPA (optional)", text: $gpa)
                        .keyboardType(.decimalPad)
                }

                Section("Athletics") {
                    TextField("Positions (comma separated)", text: $positions)
                    TextField("Primary Sports", text: $primarySports)
                    TextField("Region", text: $region)
                }

                Section("Highlights") {
                    if playerClips.isEmpty {
                        Text("No clips for this player yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(playerClips) { clip in
                            Toggle(isOn: Binding(
                                get: { profile.highlightClipIDs.contains(clip.id) },
                                set: { isSelected in
                                    if isSelected {
                                        profile.highlightClipIDs.append(clip.id)
                                    } else {
                                        profile.highlightClipIDs.removeAll { $0 == clip.id }
                                    }
                                }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(clip.title.isEmpty ? "Highlight" : clip.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Stats History") {
                    if profile.statsHistory.isEmpty {
                        Text("No stats history added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(profile.statsHistory) { snapshot in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(snapshot.seasonLabel)
                                    .font(.subheadline.weight(.semibold))
                                Text(snapshotSummary(snapshot))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button("Populate from seasons") {
                        profile.statsHistory = seasonSnapshots()
                    }
                }

                Section("Public Profile") {
                    Toggle("Public Link", isOn: $profile.isPublic)
                    Toggle("Visible to Recruiters", isOn: $profile.isRecruiterVisible)
                    if let url = profile.publicProfileURL {
                        Text(url.absoluteString)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Share Profile") {
                            profile.lastSharedAt = Date()
                            showShareSheet = true
                        }
                    } else {
                        Text("Enable to generate a public share link.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Recruiting Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = profile.publicProfileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private var playerClips: [Clip] {
        clipStore.clips(forPlayerID: playerID)
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func saveProfile() {
        profile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.height = height.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.weight = weight.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.gradYear = Int(gradYear.trimmingCharacters(in: .whitespacesAndNewlines))
        profile.gpa = Double(gpa.trimmingCharacters(in: .whitespacesAndNewlines))
        profile.positions = positions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        profile.primarySports = primarySports.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        profile.region = region.trimmingCharacters(in: .whitespacesAndNewlines)
        if profile.publicProfileID.isEmpty {
            profile.publicProfileID = UUID().uuidString
        }

        guard var team = teamStore.teams.first(where: { $0.id == teamID }),
              let index = team.players.firstIndex(where: { $0.id == playerID })
        else { return }

        var updatedPlayer = team.players[index]
        updatedPlayer.profile = profile
        onSave(updatedPlayer)
    }

    private func seasonSnapshots() -> [PlayerSeasonSnapshot] {
        guard let team = teamStore.teams.first(where: { $0.id == teamID }) else { return [] }
        let sport = SportCatalog.sport(for: team.sportID)
        let seasons = teamStore.seasons(for: teamID)
        let matchesBySeason = Dictionary(grouping: team.matches, by: { $0.seasonID })
        let primaryStatID = sport.scoringRules.primaryStatID

        return seasons.map { season in
            let matches = matchesBySeason[season.id] ?? []
            let total = matches.reduce(0) { total, match in
                guard let line = match.playerStats[playerID] else { return total }
                return total + line.value(for: primaryStatID)
            }
            return PlayerSeasonSnapshot(
                seasonID: season.id,
                seasonLabel: season.name,
                statSummary: [primaryStatID: total]
            )
        }
    }

    private func snapshotSummary(_ snapshot: PlayerSeasonSnapshot) -> String {
        if snapshot.statSummary.isEmpty {
            return "No stats recorded"
        }
        return snapshot.statSummary.map { key, value in "\(key): \(value)" }.sorted().joined(separator: " • ")
    }
}
