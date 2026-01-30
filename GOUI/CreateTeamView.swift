import SwiftUI

struct CreateTeamView: View {

    var teamStore: TeamStore
    var onCreated: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var analytics: AnalyticsService
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var permissionService: PermissionService

    @State private var name: String = ""
    @State private var fieldSize: Int = 11
    @State private var primaryFormation: Formation = .f433
    @State private var players: [Player] = []
    @State private var showAddPlayer = false
    @State private var sportID: String = SportCatalog.defaultSportID
    @State private var showCoachLimitAlert = false

    private var sport: any SportDefinition {
        SportCatalog.sport(for: sportID)
    }

    private var fieldSizeOptions: [Int] {
        switch sport.id {
        case SportCatalog.basketballID:
            return [5]
        case SportCatalog.waterPoloID:
            return [7]
        case SportCatalog.volleyballID:
            return [6]
        case SportCatalog.tennisID:
            return [2, 4]
        case SportCatalog.golfID:
            return [1, 2, 4]
        default:
            return [7, 9, 11]
        }
    }

    private var sortedPlayers: [Player] {
        players.sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.number < rhs.number
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("TEAM") {
                    TextField("Team name", text: $name)
                    NavigationLink {
                        SportPickerView(selectedSportID: $sportID)
                    } label: {
                        HStack {
                            Text("Sport")
                            Spacer()
                            Text(sport.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if sport.supportsTeamScore {
                        Picker("Field size", selection: $fieldSize) {
                            ForEach(fieldSizeOptions, id: \.self) { value in
                                Text("\(value)v\(value)").tag(value)
                            }
                        }
                    }

                    if sport.supportsPositions {
                        Picker("Primary Formation", selection: $primaryFormation) {
                            ForEach(Formation.allCases) { formation in
                                Text(formation.rawValue).tag(formation)
                            }
                        }
                    }
                }

                Section("PLAYERS") {
                    if sortedPlayers.isEmpty {
                        Text("Add your players during setup to build the roster.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedPlayers) { player in
                            HStack {
                                Text("#\(player.number)")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(GoStatsTheme.text)
                                    .frame(width: 48, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(player.displayPosition(for: sport) ?? "No Position")
                                        .font(.system(size: 12))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                                Spacer()
                            }
                        }
                        .onDelete { offsets in
                            players.remove(atOffsets: offsets)
                        }
                    }

                    Button {
                        showAddPlayer = true
                    } label: {
                        Label("Add Player", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button {
                        create()
                    } label: {
                        Text("Create Team")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Create Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
            .sheet(isPresented: $showAddPlayer) {
            CreatePlayerView(onCreate: { player in
                players.append(player)
            }, sport: sport)
        }
        .alert("Coach Team Limit", isPresented: $showCoachLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(permissionService.coachLimitMessage())
        }
        .onChange(of: sportID) { _, _ in
            if let first = fieldSizeOptions.first {
                fieldSize = first
            }
        }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let starterIDs = sortedPlayers.prefix(fieldSize).map(\.id)
        let goalkeeperDepth = Team.goalkeeperDepthIDs(from: sortedPlayers)
        let team = Team(
            id: UUID(),
            name: trimmed,
            players: sortedPlayers,
            fieldSize: fieldSize,
            startingOnFieldIDs: starterIDs,
            primaryFormation: primaryFormation,
            primaryGoalkeeperID: sport.supportsGoalie ? goalkeeperDepth.primary : nil,
            secondaryGoalkeeperID: sport.supportsGoalie ? goalkeeperDepth.secondary : nil,
            thirdGoalkeeperID: sport.supportsGoalie ? goalkeeperDepth.third : nil,
            sportID: sportID,
            matches: []
        )

        teamStore.addTeam(team)
        analytics.log(.createdTeam, metadata: ["teamID": team.id.uuidString])
        if permissionService.canAssignCoachRole(teamID: team.id, role: .coachManager) {
            membershipStore.requestJoin(teamID: team.id, userID: roleManager.userID, role: .coachManager)
            if let pending = membershipStore.membershipRecord(for: team.id, userID: roleManager.userID) {
                membershipStore.approveMembership(pending)
            }
        } else {
            membershipStore.requestJoin(teamID: team.id, userID: roleManager.userID, role: .viewer)
            if let pending = membershipStore.membershipRecord(for: team.id, userID: roleManager.userID) {
                membershipStore.approveMembership(pending)
            }
            showCoachLimitAlert = true
        }
        onCreated(team.id)
        dismiss()
    }
}
