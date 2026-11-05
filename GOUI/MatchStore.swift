import Foundation
import SwiftUI

final class MatchSessionStore: ObservableObject {

    // MARK: - Session lifecycle
    @Published var isActive: Bool = false
    @Published var startTime: Date? = nil
    @Published var elapsedTime: TimeInterval = 0

    // MARK: - Score
    @Published var goalsFor: Int = 0
    @Published var goalsAgainst: Int = 0

    // MARK: - Timer
    @Published var isRunning: Bool = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published var matchEnded: Bool = false

    // MARK: - Periods (halves or quarters)
    /// 1-based period the clock is in.
    @Published private(set) var currentPeriod: Int = 1
    /// 2 = halves, 4 = quarters.
    @Published var periodCount: Int = 2
    /// Minutes per period; 0 = no set length.
    @Published var periodMinutes: Int = 0
    /// Match clock value when the current period started.
    @Published private(set) var periodStartSeconds: Int = 0
    /// True once the current period's time has run out (cleared when it ends).
    @Published var periodTimeUp: Bool = false

    /// Kept for older code: true after the first period ends.
    var hasSplitHalf: Bool { currentPeriod > 1 }
    var isFinalPeriod: Bool { currentPeriod >= periodCount }

    /// "1st half", "2nd half", "Q3"
    var periodName: String {
        if periodCount == 4 { return "Q\(currentPeriod)" }
        return currentPeriod == 1 ? "1st half" : "2nd half"
    }

    /// Header label: "1ST HALF", "QUARTER 3"
    var periodLabel: String {
        if periodCount == 4 { return "QUARTER \(currentPeriod)" }
        return currentPeriod == 1 ? "1ST HALF" : "2ND HALF"
    }

    /// Seconds left in the current period (negative = stoppage time), or nil if no set length.
    var periodSecondsRemaining: Int? {
        guard periodMinutes > 0 else { return nil }
        return periodMinutes * 60 - (elapsedSeconds - periodStartSeconds)
    }

    /// e.g. "2 × 25 min", "4 × 12 min", "2 halves"
    var formatDescription: String {
        let unit = periodCount == 4 ? "quarters" : "halves"
        return periodMinutes > 0 ? "\(periodCount) × \(periodMinutes) min" : "\(periodCount) \(unit)"
    }

    private var startDate: Date? = nil {
        didSet { startTime = startDate }
    }
    private var accumulatedSeconds: Int = 0
    private var lastPlayerUpdateSeconds: Int = 0
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
    @Published var onFieldLineupIDs: [UUID] = []
    var goalkeeperDepthIDs: [UUID] = []

    // MARK: - Events
    @Published var events: [MatchEvent] = []

    // MARK: - Undo
    private var undoStack: [Snapshot] = []

    struct Snapshot {
        let goalsFor: Int
        let goalsAgainst: Int
        let events: [MatchEvent]
        let players: [Player]
        let onFieldIDs: Set<UUID>
        let onFieldLineupIDs: [UUID]
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
        if !onFieldLineupIDs.isEmpty {
            return onFieldLineupIDs.compactMap { id in
                players.first(where: { $0.id == id })
            }
        }
        let set = onFieldIDs
        return players.filter { set.contains($0.id) }
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    // MARK: - Controls
    func startGame() {
        guard !isRunning, !matchEnded else { return }
        isActive = true
        isRunning = true
        startDate = Date()
        lastPlayerUpdateSeconds = elapsedSeconds
        startTimer()
        refreshElapsedFromClock()
        persist()
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
        persist()
    }

    /// Ends the current period (halftime, or end of a quarter). The match clock
    /// NEVER resets: it continues from its current value when Resume is tapped, and
    /// the next period's time-left countdown starts from here.
    func splitHalf() {
        guard !isFinalPeriod else { return }
        let ended = periodCount == 4 ? "End of Q\(currentPeriod)" : "Halftime"
        currentPeriod += 1
        periodStartSeconds = elapsedSeconds
        periodTimeUp = false
        updateLiveActivity(lastEvent: ended)
        persist()
    }

    /// Same as splitHalf(); clearer name for quarters.
    func endPeriod() { splitHalf() }

    /// Legacy name kept for backward compatibility
    func splitHalfAndResume() {
        splitHalf()
    }

    /// State 7: Permanently freeze the timer. No resume possible after this.
    func endMatchFreeze() {
        refreshElapsedFromClock()
        stopTimer()
        isRunning = false
        matchEnded = true
        startDate = nil
        // Keep the saved state until the coach taps Save or Discard on the End sheet
        // (both call resetForNewMatch, which clears it). Clearing here would lose the
        // whole game if the app died while the End sheet was open.
        persist()
        LiveActivityManager.shared.endActivity()
    }

    private var lastLiveActivityUpdate: Int = -10
    private var lastPersistSeconds: Int = 0

    func refreshElapsedFromClock() {
        if isRunning, let startDate {
            let delta = max(0, Int(Date().timeIntervalSince(startDate)))
            elapsedSeconds = accumulatedSeconds + delta
        } else {
            elapsedSeconds = accumulatedSeconds
        }
        elapsedTime = TimeInterval(elapsedSeconds)
        updatePlayerSecondsIfNeeded()

        // Period time ran out: buzz once and let the coach decide (refs add stoppage time).
        if isRunning, !periodTimeUp, let left = periodSecondsRemaining, left <= 0 {
            periodTimeUp = true
            Haptics.warning()
        }

        // Save the running match every 15 seconds so a crash loses at most ~15s of minutes
        if isRunning, elapsedSeconds - lastPersistSeconds >= 15 {
            persist()
        }

        // Update Live Activity every 5 seconds to avoid throttling
        if isRunning, LiveActivityManager.shared.isActive, elapsedSeconds - lastLiveActivityUpdate >= 5 {
            lastLiveActivityUpdate = elapsedSeconds
            updateLiveActivity()
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
        isActive = false
        startTime = nil
        elapsedTime = 0
        accumulatedSeconds = 0
        elapsedSeconds = 0
        currentPeriod = 1
        periodStartSeconds = 0
        periodTimeUp = false
        matchEnded = false
        MatchStatePersistence.clear()
        lastPlayerUpdateSeconds = 0
        lastPersistSeconds = 0

        goalsFor = 0
        goalsAgainst = 0
        events.removeAll()

        undoStack.removeAll()

        currentTeamID = team?.id
        currentSeasonID = seasonID

        if let team {
            fieldSize = team.fieldSize
            periodCount = team.periodCount == 4 ? 4 : 2
            periodMinutes = max(0, team.periodMinutes)

            // Ensure formation matches team's field size
            if let f = formation, f.playerCount == fieldSize {
                self.formation = f
            } else if let f = Formation.allCases.first(where: { $0.playerCount == fieldSize }) {
                self.formation = f
            } else {
                self.formation = formation
            }

            players = team.players.map { player in
                var resetPlayer = player
                resetPlayer.secondsPlayed = 0
                resetPlayer.goals = 0
                resetPlayer.assists = 0
                resetPlayer.shots = 0
                resetPlayer.shotsOnTarget = 0
                resetPlayer.yellowCards = 0
                resetPlayer.redCards = 0
                resetPlayer.saves = 0
                resetPlayer.goalsConceded = 0
                resetPlayer.pkFaced = 0
                resetPlayer.pkSaved = 0
                resetPlayer.pkConceded = 0
                resetPlayer.pkGoals = 0
                resetPlayer.pkAttempts = 0
                return resetPlayer
            }
            let depth = Team.goalkeeperDepthIDs(
                from: team.players,
                currentPrimary: team.primaryGoalkeeperID,
                currentSecondary: team.secondaryGoalkeeperID,
                currentThird: team.thirdGoalkeeperID
            )
            goalkeeperDepthIDs = [depth.primary, depth.secondary, depth.third].compactMap { $0 }
            onFieldLineupIDs = team.startingOnFieldIDs
            onFieldIDs = Set(team.startingOnFieldIDs)

            // Goalkeeper auto-placement: ensure marked goalie is in the GK formation slot
            if let gkID = goalkeeperDepthIDs.first {
                let fm = formation ?? team.primaryFormation
                if let gkSlotIdx = fm.slotPositions.firstIndex(of: .gk),
                   gkSlotIdx < onFieldLineupIDs.count,
                   onFieldLineupIDs[gkSlotIdx] != gkID,
                   onFieldIDs.contains(gkID) {
                    // Swap the GK into the correct slot
                    if let currentIdx = onFieldLineupIDs.firstIndex(of: gkID) {
                        onFieldLineupIDs.swapAt(gkSlotIdx, currentIdx)
                    }
                }
            }
        } else {
            fieldSize = 7
            players = []
            onFieldIDs = []
            onFieldLineupIDs = []
            goalkeeperDepthIDs = []
        }
    }

    func resumeIfNeeded() {
        guard isActive, !isRunning else { return }
        startGame()
    }

    // MARK: - Persistence

    /// Writes the in-progress match to disk. Called after every event, sub, undo,
    /// clock change, every 15s while running, and when the app goes to the background.
    func persist() {
        guard isActive else { return }
        lastPersistSeconds = elapsedSeconds
        MatchStatePersistence.save(from: self, teamName: liveActivityTeamName, opponent: liveActivityOpponent)
    }

    /// Kept for existing callers.
    func saveState(teamName: String, opponent: String) {
        if !teamName.isEmpty { liveActivityTeamName = teamName }
        if !opponent.isEmpty { liveActivityOpponent = opponent }
        persist()
    }

    /// Restores a match saved by `persist()`. If the clock was running when the app
    /// died and it was closed for 15 minutes or less, that time is added back and the
    /// clock keeps running, crediting those minutes to the players who were on the field.
    /// A longer gap (e.g. reopened the next day) restores paused, with no minutes added.
    func restoreState(_ state: MatchStatePersistence.PersistedState) {
        stopTimer()
        isActive = state.isActive
        goalsFor = state.goalsFor
        goalsAgainst = state.goalsAgainst
        periodCount = state.periodCount ?? 2
        periodMinutes = state.periodMinutes ?? 0
        currentPeriod = state.currentPeriod ?? (state.hasSplitHalf ? 2 : 1)
        periodStartSeconds = state.periodStartSeconds ?? 0
        periodTimeUp = false
        matchEnded = state.matchEnded == true
        events = state.events
        fieldSize = state.fieldSize
        currentTeamID = state.currentTeamID
        currentSeasonID = state.currentSeasonID
        liveActivityTeamName = state.teamName
        liveActivityOpponent = state.opponentName
        undoStack.removeAll()

        if let savedPlayers = state.players { players = savedPlayers }
        if let ids = state.onFieldIDs { onFieldIDs = Set(ids) }
        if let lineup = state.onFieldLineupIDs { onFieldLineupIDs = lineup }
        if let savedFormation = state.formation { formation = savedFormation }
        if let depth = state.goalkeeperDepthIDs { goalkeeperDepthIDs = depth }

        var wasRunning = state.wasRunning == true && state.isActive && !matchEnded
        var gap = 0
        if wasRunning, let savedAt = state.savedAt {
            gap = max(0, Int(Date().timeIntervalSince(savedAt)))
            if gap > 15 * 60 {
                // Too long to be a quick crash-and-reopen: don't invent minutes.
                gap = 0
                wasRunning = false
            }
        }

        accumulatedSeconds = state.elapsedSeconds + gap
        elapsedSeconds = accumulatedSeconds
        elapsedTime = TimeInterval(elapsedSeconds)
        lastPersistSeconds = elapsedSeconds

        if wasRunning {
            // Credit the time the app was closed to the players who were on the field.
            if gap > 0 {
                for id in onFieldIDs {
                    updatePlayerStats(id: id) { p in p.secondsPlayed += gap }
                }
            }
            lastPlayerUpdateSeconds = elapsedSeconds
            isRunning = true
            startDate = Date()
            startTimer()
            // Replace any frozen lock-screen activity left by the killed launch.
            if ProAccess.isPro {
            LiveActivityManager.shared.startActivity(
                teamName: liveActivityTeamName.isEmpty ? "Home" : liveActivityTeamName,
                opponentName: liveActivityOpponent.isEmpty ? "Opponent" : liveActivityOpponent
            )
            updateLiveActivity()
            }
        } else {
            lastPlayerUpdateSeconds = elapsedSeconds
            isRunning = false
            startDate = nil
        }
        persist()
    }

    func clearPersistedState() {
        MatchStatePersistence.clear()
    }

    // MARK: - Undo
    func pushUndo() {
        undoStack.append(
            Snapshot(
                goalsFor: goalsFor,
                goalsAgainst: goalsAgainst,
                events: events,
                players: players,
                onFieldIDs: onFieldIDs,
                onFieldLineupIDs: onFieldLineupIDs,
                formation: formation,
                fieldSize: fieldSize
            )
        )
    }

    func undoLast() {
        guard let snap = undoStack.popLast() else { return }
        goalsFor = snap.goalsFor
        goalsAgainst = snap.goalsAgainst
        events = snap.events
        // Restore stats from the snapshot but keep minutes played as they are now:
        // undoing an event must not erase time the players actually spent on the field.
        let currentSeconds = Dictionary(players.map { ($0.id, $0.secondsPlayed) }, uniquingKeysWith: { a, _ in a })
        players = snap.players.map { p in
            var restored = p
            restored.secondsPlayed = currentSeconds[p.id] ?? p.secondsPlayed
            return restored
        }
        onFieldIDs = snap.onFieldIDs
        onFieldLineupIDs = snap.onFieldLineupIDs
        formation = snap.formation
        fieldSize = snap.fieldSize
        markPlayerSecondsBaseline() // also saves the match
    }

    // MARK: - Events + Stats
    func recordGoal(scorer: Player, assist: Player?) {
        pushUndo()
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
        pushUndo()
        updatePlayerStats(id: shooter.id) { p in
            p.shots += 1
            if onTarget { p.shotsOnTarget += 1 }
            if isPenalty { p.pkAttempts += 1 }
        }
        let label = isPenalty ? "PK Attempt" : "Shot"
        addEvent(
            kind: isPenalty ? .pkAttempt : .shot,
            title: "\(label) — \(displayName(for: shooter))",
            detail: onTarget ? "On Target" : "Off Target"
        )
    }

    func recordPKMade(shooter: Player) {
        pushUndo()
        goalsFor += 1
        updatePlayerStats(id: shooter.id) { p in
            p.goals += 1
            p.shots += 1
            p.shotsOnTarget += 1
            p.pkGoals += 1
            p.pkAttempts += 1
        }
        addEvent(
            kind: .pkMade,
            title: "PK Made — \(displayName(for: shooter))",
            detail: nil
        )
    }

    func recordOwnGoal(player: Player) {
        pushUndo()
        goalsAgainst += 1
        addEvent(
            kind: .ownGoal,
            title: "Own Goal — \(displayName(for: player))",
            detail: nil
        )
    }

    func recordCard(player: Player, card: CardType) {
        pushUndo()
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
        pushUndo()
        updatePlayerStats(id: keeper.id) { p in
            p.saves += 1
        }
        addEvent(kind: .save, title: "Save — \(displayName(for: keeper))", detail: nil)
    }

    func recordKeeperConceded(isPenalty: Bool = false) {
        guard let keeper = activeGoalkeeper() else {
            // No keeper on the field (common in small-sided games): still count the goal.
            pushUndo()
            goalsAgainst += 1
            addEvent(
                kind: isPenalty ? .pkConceded : .conceded,
                title: isPenalty ? "PK Conceded" : "Opponent Goal",
                detail: nil
            )
            return
        }
        pushUndo()
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
        pushUndo()
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
        updateLiveActivity(lastEvent: title)
        persist()
    }

    // MARK: - Live Activity Bridge

    /// The opponent name for the current match (set when Live Activity starts)
    var liveActivityOpponent: String = ""

    /// The team name for the current match
    var liveActivityTeamName: String = ""

    func updateLiveActivity(lastEvent: String = "") {
        LiveActivityManager.shared.updateActivity(
            homeScore: goalsFor,
            awayScore: goalsAgainst,
            elapsedSeconds: elapsedSeconds,
            hasSplitHalf: hasSplitHalf,
            periodLabel: periodLabel,
            teamName: liveActivityTeamName,
            opponentName: liveActivityOpponent,
            lastEvent: lastEvent
        )
    }

    func activeGoalkeeper() -> Player? {
        if let lineupKeeper = lineupGoalkeeper() {
            return lineupKeeper
        }
        if let primaryID = goalkeeperDepthIDs.first,
           onFieldIDs.contains(primaryID),
           let keeper = players.first(where: { $0.id == primaryID }) {
            return keeper
        }
        if !goalkeeperDepthIDs.isEmpty {
            for id in goalkeeperDepthIDs where onFieldIDs.contains(id) {
                if let keeper = players.first(where: { $0.id == id }) {
                    return keeper
                }
            }
        }
        // Only a keeper who is actually on the field. (Falling back to a benched GK
        // credited saves and goals against to a player who wasn't playing.)
        return onFieldPlayers.first(where: { $0.position == .gk })
    }

    private func lineupGoalkeeper() -> Player? {
        let formation = formation ?? .f433
        let slots = formation.slotPositions
        guard let gkIndex = slots.firstIndex(of: .gk),
              onFieldLineupIDs.indices.contains(gkIndex) else {
            return nil
        }
        let gkID = onFieldLineupIDs[gkIndex]
        guard onFieldIDs.contains(gkID) else { return nil }
        return players.first(where: { $0.id == gkID })
    }

    func promoteGoalkeeper(_ id: UUID) {
        if let index = goalkeeperDepthIDs.firstIndex(of: id) {
            goalkeeperDepthIDs.remove(at: index)
        }
        goalkeeperDepthIDs.insert(id, at: 0)
        let unique = Array(NSOrderedSet(array: goalkeeperDepthIDs)) as? [UUID] ?? goalkeeperDepthIDs
        goalkeeperDepthIDs = unique
    }

    /// Called after every substitution (manual, voice, line change), so it also saves the match.
    func markPlayerSecondsBaseline() {
        lastPlayerUpdateSeconds = elapsedSeconds
        persist()
    }

    private func updatePlayerSecondsIfNeeded() {
        guard isRunning else {
            lastPlayerUpdateSeconds = elapsedSeconds
            return
        }
        let delta = elapsedSeconds - lastPlayerUpdateSeconds
        guard delta > 0 else { return }
        for id in onFieldIDs {
            updatePlayerStats(id: id) { p in
                p.secondsPlayed += delta
            }
        }
        lastPlayerUpdateSeconds = elapsedSeconds
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
        let depth = Team.goalkeeperDepthIDs(from: sample)
        goalkeeperDepthIDs = [depth.primary, depth.secondary, depth.third].compactMap { $0 }
        onFieldLineupIDs = sample.map { $0.id }
        onFieldIDs = Set(sample.map { $0.id })
    }
}

typealias MatchStore = MatchSessionStore
