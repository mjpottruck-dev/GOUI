import SwiftUI

struct CreateTeamView: View {

    var teamStore: TeamStore
    var onCreated: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var fieldSize: Int = 11
    @State private var primaryFormation: Formation = .f433
    @State private var players: [Player] = []
    @State private var showAddPlayer = false

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
                    Picker("Field size", selection: $fieldSize) {
                        Text("7v7").tag(7)
                        Text("9v9").tag(9)
                        Text("11v11").tag(11)
                    }

                    Picker("Primary Formation", selection: $primaryFormation) {
                        ForEach(Formation.allCases) { formation in
                            Text(formation.rawValue).tag(formation)
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
                                    Text(player.position.rawValue)
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
            CreatePlayerView { player in
                players.append(player)
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
            primaryGoalkeeperID: goalkeeperDepth.primary,
            secondaryGoalkeeperID: goalkeeperDepth.secondary,
            thirdGoalkeeperID: goalkeeperDepth.third,
            matches: []
        )

        teamStore.addTeam(team)
        onCreated(team.id)
        dismiss()
    }
}
