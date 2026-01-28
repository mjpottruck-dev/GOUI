import Foundation
import SwiftUI

final class MatchStore: ObservableObject {

    // MARK: - Score
    @Published var goalsFor: Int = 0
    @Published var goalsAgainst: Int = 0

    // MARK: - Timer
    @Published var isRunning: Bool = false
    @Published private(set) var elapsedSeconds: Int = 0
    var secondsElapsed: Int { elapsedSeconds }

    // Team + formation for current session
    @Published var currentTeamID: UUID? = nil
    @Published var formation: Formation? = nil

    // Field size
    @Published var fieldSize: Int = 7

    // MARK: - Roster + on-field
    @Published var players: [Player] = []
    @Published var onFieldIDs: Set<UUID> = []

    // MARK: - Undo
    private var undoStack: [Snapshot] = []

    struct Snapshot {
        let goalsFor: Int
        let goalsAgainst: Int
        let elapsedSeconds: Int
        let isRunning: Bool
        let fieldSize: Int
        let players: [Player]
        let onFieldIDs: Set<UUID>
        let formation: Formation?
        let currentTeamID: UUID?
    }

    // MARK: - Computed
    var timeString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Controls
    func startGame() { isRunning = true }
    func pauseGame() { isRunning = false }

    func tickOneSecond() {
        guard isRunning else { return }
        elapsedSeconds += 1
    }

    // MARK: - Reset (NEW)
    func resetForNewMatch(team: Team?, formation: Formation?) {
        // stop time
        isRunning = false
        elapsedSeconds = 0

        // reset score
        goalsFor = 0
        goalsAgainst = 0

        // clear undo
        undoStack.removeAll()

        // set team context
        currentTeamID = team?.id
        self.formation = formation

        // roster/field setup
        if let team {
            fieldSize = team.fieldSize
            players = team.players
            onFieldIDs = Set(team.startingOnFieldIDs)
        } else {
            fieldSize = 7
            players = []
            onFieldIDs = []
        }

        // if no lineup, load sample to keep UI alive
        if players.isEmpty {
            loadSampleIfEmpty()
        }
    }

    // MARK: - Undo
    func pushUndo() {
        undoStack.append(
            Snapshot(
                goalsFor: goalsFor,
                goalsAgainst: goalsAgainst,
                elapsedSeconds: elapsedSeconds,
                isRunning: isRunning,
                fieldSize: fieldSize,
                players: players,
                onFieldIDs: onFieldIDs,
                formation: formation,
                currentTeamID: currentTeamID
            )
        )
        if undoStack.count > 50 { undoStack.removeFirst() }
    }

    func undoLast() {
        guard let snap = undoStack.popLast() else { return }
        goalsFor = snap.goalsFor
        goalsAgainst = snap.goalsAgainst
        elapsedSeconds = snap.elapsedSeconds
        isRunning = snap.isRunning
        fieldSize = snap.fieldSize
        players = snap.players
        onFieldIDs = snap.onFieldIDs
        formation = snap.formation
        currentTeamID = snap.currentTeamID
    }

    // MARK: - Sample roster
    func loadSampleIfEmpty() {
        guard players.isEmpty else { return }

        fieldSize = 11

        let sample: [Player] = [
            Player(name: "Keeper", number: 1, position: .gk),

            Player(name: "RB", number: 2, position: .rb),
            Player(name: "CB", number: 4, position: .cb),
            Player(name: "CB", number: 5, position: .cb),
            Player(name: "LB", number: 3, position: .lb),

            Player(name: "CM", number: 8, position: .cm),
            Player(name: "CDM", number: 6, position: .cdm),
            Player(name: "CM", number: 10, position: .cm),

            Player(name: "RW", number: 7, position: .rw),
            Player(name: "ST", number: 9, position: .st),
            Player(name: "LW", number: 11, position: .lw)
        ]

        players = sample
        onFieldIDs = Set(sample.map { $0.id })
    }
}

