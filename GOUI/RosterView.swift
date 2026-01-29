import SwiftUI

struct RosterView: View {
    @Binding var team: Team

    @State private var showingAddPlayer = false

    private var sport: any SportDefinition {
        SportCatalog.sport(for: team.sportID)
    }

    var body: some View {
        List {
            Section {
                if team.players.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No players yet").font(.headline)
                        Text("Tap + to add your first player.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(team.players.sorted(by: sortPlayers)) { player in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(player.number) • \(player.name)")
                                    .font(.headline)
                                Text(player.displayPosition(for: sport) ?? "No Position")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deletePlayers)
                }
            } header: {
                Text("Players")
            }
        }
        .navigationTitle("Roster")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddPlayer = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            AddPlayerView(onCreate: { newPlayer in
                team.players.append(newPlayer)
            }, sport: sport)
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        team.players.remove(atOffsets: offsets)
    }

    private func sortPlayers(_ a: Player, _ b: Player) -> Bool {
        let order: [Position: Int] = [.gk: 0, .def: 1, .mid: 2, .fw: 3]
        let pa = order[a.position] ?? 99
        let pb = order[b.position] ?? 99
        if pa != pb { return pa < pb }
        return a.number < b.number
    }
}
