import SwiftUI

struct TeamRosterView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore
    let teamID: UUID

    @State private var showingAddPlayer = false
    @State private var editingPlayer: Player? = nil
    @State private var searchText: String = ""
    @State private var selectedFilter: RosterFilter = .all
    @State private var displayedPlayers: [Player] = []
    @State private var refreshTask: Task<Void, Never>? = nil
    @State private var showPermissionAlert = false
    @State private var showSwitcher = false
    @State private var showMembers = false

    @EnvironmentObject var permissionService: PermissionService
    @EnvironmentObject var appState: AppState

    private var sport: any SportDefinition {
        SportCatalog.sport(for: team?.sportID)
    }

    private var teamIndex: Int? {
        teamStore.teams.firstIndex(where: { $0.id == teamID })
    }

    private var team: Team? {
        guard let idx = teamIndex else { return nil }
        return teamStore.teams[idx]
    }

    var body: some View {
        let _ = DebugRenderLogger.log("RosterView", enabled: DebugSettings.renderCountsEnabled)

        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        rosterHeader

                        rosterFilters

                        recruitingProfiles

                        if displayedPlayers.isEmpty {
                            emptyState
                        } else {
                            ForEach(displayedPlayers) { player in
                                PlayerRowView(
                                    player: player,
                                    isStarter: team?.startingOnFieldIDs.contains(player.id) == true,
                                    sport: sport
                                )
                                .equatable()
                                .onTapGesture {
                                    guard permissionService.canEditRoster(teamID: teamID) else {
                                        showPermissionAlert = true
                                        return
                                    }
                                    editingPlayer = player
                                }
                                .swipeActions(edge: .trailing) {
                                    if permissionService.canEditRoster(teamID: teamID) {
                                        Button(role: .destructive) {
                                            deletePlayer(player)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(team?.name ?? "Roster")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSwitcher = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                if permissionService.canManageMembers(teamID: teamID) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Members") {
                            showMembers = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView(onCreate: { newPlayer in
                    addPlayer(newPlayer)
                }, sport: sport)
            }
            .sheet(isPresented: $showSwitcher) {
                TeamSwitcherSheet(teamStore: teamStore) { picked in
                    appState.currentTeamID = picked
                }
            }
            .sheet(isPresented: $showMembers) {
                TeamMembersSheet(teamID: teamID)
            }
            .sheet(item: $editingPlayer) { player in
                EditPlayerSheet(player: player, sport: sport) { updated in
                    updatePlayer(updated)
                }
            }
            .onAppear {
                refreshPlayers()
            }
            .onChange(of: searchText) { _, _ in
                refreshPlayers()
            }
            .onChange(of: selectedFilter) { _, _ in
                refreshPlayers()
            }
            .onChange(of: teamStore.teams) { _, _ in
                refreshPlayers()
            }
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Coach access is required to edit the roster.")
            }
        }
    }

    private var rosterHeader: some View {
        GlassCard(level: .raised) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Roster")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("\(team?.players.count ?? 0) players")
                            .font(.footnote)
                            .foregroundStyle(GoStatsTheme.text2)
                        if let joinCode = team?.joinCode {
                            Text("Join Code: \(joinCode)")
                                .font(.footnote)
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }
                    Spacer()
                    Button {
                        guard permissionService.canEditRoster(teamID: teamID) else {
                            showPermissionAlert = true
                            return
                        }
                        showingAddPlayer = true
                    } label: {
                        Label("Add Player", systemImage: "plus")
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary))
                }
            }
        }
    }

    private var rosterFilters: some View {
        GlassCard(level: .surface) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Filters")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                Picker("Roster Filter", selection: $selectedFilter) {
                    Text("All").tag(RosterFilter.all)
                    Text("Starters").tag(RosterFilter.starters)
                    if sport.supportsGoalie {
                        Text("Goalies").tag(RosterFilter.goalies)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var recruitingProfiles: some View {
        GlassCard(level: .surface) {
            NavigationLink {
                PlayerProfilesView(teamStore: teamStore, teamID: teamID, clipStore: clipStore)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(GoStatsTheme.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recruiting Profiles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("Manage public links, bios, and highlights")
                            .font(.system(size: 12))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(GoStatsTheme.text2)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        GlassCard(level: .surface) {
            VStack(alignment: .leading, spacing: 6) {
                Text("No players yet")
                    .font(.headline)
                Text("Tap “Add Player” to build your roster.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func refreshPlayers() {
        refreshTask?.cancel()
        let players = team?.players ?? []
        let starters = Set(team?.startingOnFieldIDs ?? [])
        let filter = selectedFilter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshTask = Task.detached { [sport] in
            let filtered = players.filter { player in
                if !query.isEmpty {
                    let match = player.name.localizedCaseInsensitiveContains(query)
                        || "\(player.number)".contains(query)
                    if !match { return false }
                }
                switch filter {
                case .all:
                    return true
                case .starters:
                    return starters.contains(player.id)
                case .goalies:
                    return sport.supportsGoalie && player.derivedIsGoalie
                }
            }

            let sorted = filtered.sorted(by: sortPlayers)
            await MainActor.run {
                displayedPlayers = sorted
            }
        }
    }

    private func addPlayer(_ player: Player) {
        teamStore.addPlayer(player, to: teamID)
    }

    private func updatePlayer(_ player: Player) {
        teamStore.updatePlayer(player, on: teamID)
    }

    private func deletePlayer(_ player: Player) {
        teamStore.deletePlayer(player, from: teamID)
    }
}

private enum RosterFilter: Hashable {
    case all
    case starters
    case goalies
}

private func sortPlayers(_ a: Player, _ b: Player) -> Bool {
    let order: [Position: Int] = [
        .gk: 0, .cb: 1, .rb: 2, .lb: 3, .rwb: 4, .lwb: 5,
        .cdm: 6, .cm: 7, .cam: 8, .rm: 9, .lm: 10,
        .rw: 11, .lw: 12, .st: 13, .cf: 14
    ]
    let pa = order[a.position] ?? 99
    let pb = order[b.position] ?? 99
    if pa != pb { return pa < pb }
    return a.number < b.number
}

private struct PlayerRowView: View, Equatable {
    let player: Player
    let isStarter: Bool
    let sport: any SportDefinition

    static func == (lhs: PlayerRowView, rhs: PlayerRowView) -> Bool {
        lhs.player.id == rhs.player.id
            && lhs.player.name == rhs.player.name
            && lhs.player.number == rhs.player.number
            && lhs.player.positionName == rhs.player.positionName
            && lhs.player.isGoalie == rhs.player.isGoalie
            && lhs.isStarter == rhs.isStarter
    }

    var body: some View {
        GlassCard(level: .surface) {
            HStack(spacing: 12) {
                Text("\(player.number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(GoStatsTheme.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(player.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)

                        if isStarter {
                            Text("Starter")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(GoStatsTheme.primary.opacity(0.18))
                                )
                                .foregroundStyle(GoStatsTheme.primary)
                        }
                    }

                    if let positionLabel = player.displayPosition(for: sport) {
                        Text(positionLabel)
                            .font(.subheadline)
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                Spacer()

                if sport.supportsGoalie, player.derivedIsGoalie {
                    Label("Goalie", systemImage: "shield.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GoStatsTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(GoStatsTheme.primary.opacity(0.18))
                        )
                }
            }
        }
    }
}

private struct EditPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var numberText: String
    @State private var position: Position
    @State private var secondaryPosition: Position?
    @State private var positionName: String
    @State private var isGoalie: Bool
    @State private var notes: String
    @State private var profile: PlayerProfile

    let playerID: UUID
    let sport: any SportDefinition
    let onSave: (Player) -> Void

    init(player: Player, sport: any SportDefinition, onSave: @escaping (Player) -> Void) {
        self._name = State(initialValue: player.name)
        self._numberText = State(initialValue: player.jersey.isEmpty ? "\(player.number)" : player.jersey)
        self._position = State(initialValue: player.position)
        self._secondaryPosition = State(initialValue: player.secondaryPosition)
        self._positionName = State(initialValue: player.positionName ?? player.position.rawValue)
        self._isGoalie = State(initialValue: player.isGoalie ?? (player.position == .gk))
        self._notes = State(initialValue: player.notes ?? "")
        self._profile = State(initialValue: player.profile)
        self.playerID = player.id
        self.sport = sport
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $name)
                    if !isNameValid {
                        Text("Name is required.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)
                    if !isNumberValid {
                        Text("Number must be between 0 and 99.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if sport.supportsPositions {
                        Picker("Primary Position", selection: $position) {
                            ForEach(Position.rosterPositions) { pos in
                                Text(pos.rawValue).tag(pos)
                            }
                        }
                        .onChange(of: position) { _, newValue in
                            positionName = newValue.rawValue
                            if sport.supportsGoalie {
                                isGoalie = newValue == .gk
                            }
                        }

                        Picker("Secondary Position", selection: $secondaryPosition) {
                            Text("None").tag(Position?.none)
                            ForEach(Position.rosterPositions) { pos in
                                Text(pos.rawValue).tag(Optional(pos))
                            }
                        }
                    } else {
                        TextField("Position (optional)", text: $positionName)
                    }

                    if sport.supportsGoalie {
                        Toggle("Goalie", isOn: $isGoalie)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmedNumber = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let number = Int(trimmedNumber) ?? 0
                        let jersey = trimmedNumber.isEmpty ? "\(number)" : trimmedNumber
                        let resolvedPositionName = positionName.isEmpty ? position.rawValue : positionName
                        let updated = Player(
                            id: playerID,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            number: number,
                            jersey: jersey,
                            position: position,
                            secondaryPosition: secondaryPosition,
                            positionName: resolvedPositionName,
                            isGoalie: sport.supportsGoalie ? isGoalie : nil,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                            profile: profile
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isNumberValid: Bool {
        let trimmed = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed) else { return false }
        return (0...99).contains(value)
    }

private var isFormValid: Bool {
        isNameValid && isNumberValid
    }
}

private struct TeamMembersSheet: View {
    let teamID: UUID

    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService
    @Environment(\.dismiss) private var dismiss

    @State private var showLimitAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pending Requests") {
                    if pendingMembers.isEmpty {
                        Text("No pending requests.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pendingMembers) { membership in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(membership.userID)
                                        .font(.subheadline.weight(.semibold))
                                    Text(membership.membershipRole.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Approve") {
                                    guard permissionService.canAssignCoachRole(teamID: teamID, role: membership.membershipRole) else {
                                        showLimitAlert = true
                                        return
                                    }
                                    membershipStore.approveMembership(membership)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Reject", role: .destructive) {
                                    membershipStore.removeMembership(membership)
                                }
                            }
                        }
                    }
                }

                Section("Active Members") {
                    if activeMembers.isEmpty {
                        Text("No active members yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeMembers) { membership in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(membership.userID)
                                        .font(.subheadline.weight(.semibold))
                                    Text(membership.membershipRole.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if membership.membershipRole.hasCoachPermissions {
                                    Text("Coach")
                                        .font(.caption2)
                                        .foregroundStyle(GoStatsTheme.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Team Members")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Coach Team Limit", isPresented: $showLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(permissionService.coachLimitMessage())
            }
        }
    }

    private var pendingMembers: [TeamMembership] {
        membershipStore.memberships(for: teamID).filter { $0.status == .pending }
    }

    private var activeMembers: [TeamMembership] {
        membershipStore.memberships(for: teamID).filter { $0.status == .active }
    }
}
