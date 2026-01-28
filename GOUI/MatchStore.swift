import Foundation
import SwiftUI

final class MatchStore: ObservableObject {

    // MARK: - Score
    @Published var goalsFor: Int = 0
    @Published var goalsAgainst: Int = 0

    // MARK: - Timer
    @Published var isRunning: Bool = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published var hasSplitHalf: Bool = false

    private var startDate: Date? = nil
    private var accumulatedSeconds: Int = 0
    private var timer: Timer?

    var secondsElapsed: Int { elapsedSeconds }

    // Team + formation for current session
    @Published var currentTeamID: UUID? = nil
    @Published var currentSeasonID: UUID? = nil
    @Published var formation: Formation? = nil

    // Field size
    @Published var fieldSize: Int = 7

    // MARK: - Roster + on-field
    @Published var players: [Player] = []
    @Published var onFieldIDs: Set<UUID> = []

    // MARK: - Events
    @Published var events: [MatchEvent] = []

    // MARK: - Undo
    private var undoStack: [Snapshot] = []

    struct Snapshot {
        let onFieldIDs: Set<UUID>
        let formation: Formation?
        let fieldSize: Int
    }

    // MARK: - Computed
    var timeString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var onFieldPlayers: [Player] {
        let set = onFieldIDs
        return players.filter { set.contains($0.id) }
    }

    // MARK: - Controls
    func startGame() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        startTimer()
        refreshElapsedFromClock()
    }

    func pauseGame() {
        guard isRunning else { return }
        let now = Date()
        if let startDate {
            accumulatedSeconds += max(0, Int(now.timeIntervalSince(startDate)))
        }
        startDate = nil
        isRunning = false
        stopTimer()
        refreshElapsedFromClock()
    }

    func splitHalfAndResume() {
        hasSplitHalf = true
        if !isRunning {
            startGame()
        }
    }

    func refreshElapsedFromClock() {
        if isRunning, let startDate {
            let delta = max(0, Int(Date().timeIntervalSince(startDate)))
            elapsedSeconds = accumulatedSeconds + delta
        } else {
            elapsedSeconds = accumulatedSeconds
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshElapsedFromClock()
        }
        timer?.tolerance = 0.2
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Reset
    func resetForNewMatch(team: Team?, formation: Formation?, seasonID: UUID?) {
        pauseGame()
        accumulatedSeconds = 0
        elapsedSeconds = 0
        hasSplitHalf = false

        goalsFor = 0
        goalsAgainst = 0
        events.removeAll()

        undoStack.removeAll()

        currentTeamID = team?.id
        currentSeasonID = seasonID
        self.formation = formation

        if let team {
            fieldSize = team.fieldSize
            players = team.players
            onFieldIDs = Set(team.startingOnFieldIDs)
        } else {
            fieldSize = 7
            players = []
            onFieldIDs = []
        }

        if players.isEmpty {
            loadSampleIfEmpty()
        }
    }

    // MARK: - Undo
    func pushUndo() {
        undoStack.append(
            Snapshot(
                onFieldIDs: onFieldIDs,
                formation: formation,
                fieldSize: fieldSize
            )
        )
    }

    func undoLast() {
        guard let snap = undoStack.popLast() else { return }
        onFieldIDs = snap.onFieldIDs
        formation = snap.formation
        fieldSize = snap.fieldSize
    }

    // MARK: - Events + Stats
    func recordGoal(scorer: Player, assist: Player?) {
        goalsFor += 1
        updatePlayerStats(id: scorer.id) { p in
            p.goals += 1
            p.shots += 1
            p.shotsOnTarget += 1
        }
        if let assist {
            updatePlayerStats(id: assist.id) { p in
                p.assists += 1
            }
        }
        addEvent(
            kind: .goal,
            title: "Goal — \(displayName(for: scorer))",
            detail: assist.map { "Assist: \(displayName(for: $0))" }
        )
    }

    func recordShot(shooter: Player, onTarget: Bool, isPenalty: Bool = false) {
        updatePlayerStats(id: shooter.id) { p in
            p.shots += 1
            if onTarget { p.shotsOnTarget += 1 }
        }
        let label = isPenalty ? "PK Attempt" : "Shot"
        addEvent(
            kind: isPenalty ? .pkAttempt : .shot,
            title: "\(label) — \(displayName(for: shooter))",
            detail: onTarget ? "On Target" : "Off Target"
        )
    }

    func recordPKMade(shooter: Player) {
        goalsFor += 1
        updatePlayerStats(id: shooter.id) { p in
            p.goals += 1
            p.shots += 1
            p.shotsOnTarget += 1
        }
        addEvent(
            kind: .pkMade,
            title: "PK Made — \(displayName(for: shooter))",
            detail: nil
        )
    }

    func recordOwnGoal(player: Player) {
        goalsAgainst += 1
        addEvent(
            kind: .ownGoal,
            title: "Own Goal — \(displayName(for: player))",
            detail: nil
        )
    }

    func recordCard(player: Player, card: CardType) {
        updatePlayerStats(id: player.id) { p in
            switch card {
            case .yellow:
                p.yellowCards += 1
            case .red:
                p.redCards += 1
            }
        }
        addEvent(
            kind: .card,
            title: "Card — \(displayName(for: player))",
            detail: card.rawValue
        )
    }

    func recordKeeperSave() {
        guard let keeper = activeGoalkeeper() else { return }
        updatePlayerStats(id: keeper.id) { p in
            p.saves += 1
        }
        addEvent(kind: .save, title: "Save — \(displayName(for: keeper))", detail: nil)
    }

    func recordKeeperConceded(isPenalty: Bool = false) {
        guard let keeper = activeGoalkeeper() else { return }
        goalsAgainst += 1
        updatePlayerStats(id: keeper.id) { p in
            p.goalsConceded += 1
            if isPenalty {
                p.pkConceded += 1
                p.pkFaced += 1
            }
        }
        addEvent(
            kind: isPenalty ? .pkConceded : .conceded,
            title: "\(isPenalty ? "PK Conceded" : "Conceded") — \(displayName(for: keeper))",
            detail: nil
        )
    }

    func recordKeeperPKSaved() {
        guard let keeper = activeGoalkeeper() else { return }
        updatePlayerStats(id: keeper.id) { p in
            p.pkSaved += 1
            p.pkFaced += 1
        }
        addEvent(kind: .pkSave, title: "PK Saved — \(displayName(for: keeper))", detail: nil)
    }

    private func updatePlayerStats(id: UUID, update: (inout Player) -> Void) {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return }
        var player = players[idx]
        update(&player)
        players[idx] = player
    }

    private func addEvent(kind: MatchActionKind, title: String, detail: String?) {
        let event = MatchEvent(kind: kind, seconds: secondsElapsed, title: title, detail: detail)
        events.insert(event, at: 0)
    }

    func activeGoalkeeper() -> Player? {
        onFieldPlayers.first(where: { $0.position == .gk })
    }

    func displayName(for player: Player, in roster: [Player]? = nil) -> String {
        let roster = roster ?? players
        let parts = player.name.split(separator: " ")
        let first = parts.first.map(String.init) ?? player.name
        let firstNames = roster.map { $0.name.split(separator: " ").first.map(String.init) ?? $0.name }
        let isDuplicate = firstNames.filter { $0 == first }.count > 1
        guard isDuplicate else { return first }
        if let last = parts.dropFirst().first {
            return "\(first) \(String(last.prefix(1)))"
        }
        return first
    }

    // MARK: - Formation validation
    func lineupFitsFormation(_ lineup: [Player]) -> Bool {
        let formation = formation ?? Formation.f433
        let slots = formation.slotPositions
        guard lineup.count == slots.count else { return true }
        let players = lineup
        var used = Array(repeating: false, count: players.count)

        func positions(for player: Player) -> [Position] {
            var positions = [player.position]
            if let secondary = player.secondaryPosition {
                positions.append(secondary)
            }
            return positions
        }

        func backtrack(_ slotIndex: Int) -> Bool {
            if slotIndex == slots.count { return true }
            let slot = slots[slotIndex]
            for i in players.indices where !used[i] {
                let matchPositions = positions(for: players[i])
                if matchPositions.contains(slot) {
                    used[i] = true
                    if backtrack(slotIndex + 1) { return true }
                    used[i] = false
                }
            }
            return false
        }

        return backtrack(0)
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
