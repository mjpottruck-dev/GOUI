import Foundation
import SwiftUI

final class MatchStore: ObservableObject {

    // MARK: - Score
    @Published var goalsFor: Int = 0
    @Published var goalsAgainst: Int = 0

    // MARK: - Timer
    @Published var isRunning: Bool = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published var currentPeriodIndex: Int = 0

    @Published var sport: any SportDefinition
    @Published private(set) var activePeriods: [PeriodDefinition] = []
    @Published var periodScores: [PeriodScore] = []
    @Published var playerHoleScores: [UUID: [Int]] = [:]
    @Published var playerHolePutts: [UUID: [Int]] = [:]
    @Published var activeTemplate: GameTemplate? = nil

    private var startDate: Date? = nil
    private var accumulatedSeconds: Int = 0
    private var lastPlayerUpdateSeconds: Int = 0
    private var timer: Timer?
    private var holeCount: Int = 0

    var secondsElapsed: Int { elapsedSeconds }

    init(sport: any SportDefinition = SportCatalog.defaultSport) {
        self.sport = sport
        self.activePeriods = resolvedPeriods(for: sport, template: nil)
        self.periodScores = activePeriods.isEmpty ? [] : Array(repeating: PeriodScore(), count: activePeriods.count)
        self.holeCount = resolvedHoleCount(for: sport, template: nil)
    }

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
        let currentPeriodIndex: Int
        let periodScores: [PeriodScore]
        let playerHoleScores: [UUID: [Int]]
        let playerHolePutts: [UUID: [Int]]
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

    func currentPeriodLabel() -> String {
        guard !activePeriods.isEmpty else {
            return currentPeriodIndex == 0 ? "Period 1" : "Period \(currentPeriodIndex + 1)"
        }
        let index = min(max(currentPeriodIndex, 0), activePeriods.count - 1)
        return activePeriods[index].name
    }

    func nextPeriodLabel() -> String? {
        let nextIndex = currentPeriodIndex + 1
        guard nextIndex < activePeriods.count else { return nil }
        return activePeriods[nextIndex].name
    }

    func hasNextPeriod() -> Bool {
        nextPeriodLabel() != nil
    }

    // MARK: - Controls
    func startGame() {
        guard !isRunning else { return }
        guard sport.supportsTimer else { return }
        isRunning = true
        startDate = Date()
        lastPlayerUpdateSeconds = elapsedSeconds
        startTimer()
        refreshElapsedFromClock()
    }

    func pauseGame() {
        guard sport.supportsTimer else { return }
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

    func advancePeriodAndResume() {
        if currentPeriodIndex < max(0, activePeriods.count - 1) {
            currentPeriodIndex += 1
        }
        if sport.supportsTimer, !isRunning {
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
        updatePlayerSecondsIfNeeded()
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
        currentPeriodIndex = 0
        lastPlayerUpdateSeconds = 0

        goalsFor = 0
        goalsAgainst = 0
        events.removeAll()
        periodScores = []
        playerHoleScores = [:]
        playerHolePutts = [:]

        undoStack.removeAll()

        currentTeamID = team?.id
        currentSeasonID = seasonID
        self.formation = formation
        if let team {
            sport = SportCatalog.sport(for: team.sportID)
        } else {
            sport = SportCatalog.defaultSport
        }

        activeTemplate = nil
        activePeriods = resolvedPeriods(for: sport, template: activeTemplate)
        periodScores = activePeriods.isEmpty ? [] : Array(repeating: PeriodScore(), count: activePeriods.count)
        holeCount = resolvedHoleCount(for: sport, template: activeTemplate)

        if let team {
            fieldSize = team.fieldSize
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
                resetPlayer.statValues = Dictionary(uniqueKeysWithValues: sport.statSchema.map { ($0.id, 0) })
                return resetPlayer
            }
            let depth = Team.goalkeeperDepthIDs(
                from: team.players,
                currentPrimary: team.primaryGoalkeeperID,
                currentSecondary: team.secondaryGoalkeeperID,
                currentThird: team.thirdGoalkeeperID
            )
            if sport.supportsGoalie {
                goalkeeperDepthIDs = [depth.primary, depth.secondary, depth.third].compactMap { $0 }
            } else {
                goalkeeperDepthIDs = []
            }
            onFieldLineupIDs = team.startingOnFieldIDs
            onFieldIDs = Set(team.startingOnFieldIDs)
        } else {
            fieldSize = 7
            players = []
            onFieldIDs = []
            onFieldLineupIDs = []
            goalkeeperDepthIDs = []
        }

        if players.isEmpty {
            loadSampleIfEmpty()
        }

        configureRosterMode()
        configureHoleTracking()
    }

    func resetForNewMatch(team: Team?, formation: Formation?, seasonID: UUID?, template: GameTemplate?) {
        resetForNewMatch(team: team, formation: formation, seasonID: seasonID)
        activeTemplate = template
        activePeriods = resolvedPeriods(for: sport, template: template)
        periodScores = activePeriods.isEmpty ? [] : Array(repeating: PeriodScore(), count: activePeriods.count)
        holeCount = resolvedHoleCount(for: sport, template: template)
        configureRosterMode()
        configureHoleTracking()
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
                fieldSize: fieldSize,
                currentPeriodIndex: currentPeriodIndex,
                periodScores: periodScores,
                playerHoleScores: playerHoleScores,
                playerHolePutts: playerHolePutts
            )
        )
    }

    func undoLast() {
        guard let snap = undoStack.popLast() else { return }
        goalsFor = snap.goalsFor
        goalsAgainst = snap.goalsAgainst
        events = snap.events
        players = snap.players
        onFieldIDs = snap.onFieldIDs
        onFieldLineupIDs = snap.onFieldLineupIDs
        formation = snap.formation
        fieldSize = snap.fieldSize
        currentPeriodIndex = snap.currentPeriodIndex
        periodScores = snap.periodScores
        playerHoleScores = snap.playerHoleScores
        playerHolePutts = snap.playerHolePutts
    }

    // MARK: - Events + Stats
    func recordEvent(
        eventType: EventType,
        primaryPlayer: Player? = nil,
        secondaryPlayer: Player? = nil,
        shotOnTarget: Bool? = nil,
        cardType: CardType? = nil
    ) {
        pushUndo()

        if let points = sport.scoringRules.points(for: eventType.id, isOpponent: false) {
            goalsFor += points
        }
        if let points = sport.scoringRules.points(for: eventType.id, isOpponent: true) {
            goalsAgainst += points
        }
        if let points = sport.scoringRules.periodPoints(for: eventType.id, isOpponent: false) {
            applyPeriodScore(delta: points, isOpponent: false)
        }
        if let points = sport.scoringRules.periodPoints(for: eventType.id, isOpponent: true) {
            applyPeriodScore(delta: points, isOpponent: true)
        }

        if let player = resolvedPrimaryPlayer(for: eventType, primaryPlayer: primaryPlayer) {
            applyStatChanges(eventType.primaryStatChanges, to: player.id)
            if let shotOnTarget, let shotStats = eventType.shotOutcomeStats {
                let changes = shotOnTarget ? shotStats.onTarget : shotStats.offTarget
                applyStatChanges(changes, to: player.id)
            }
            if let cardType, let cardChanges = eventType.cardStatChanges[cardType] {
                applyStatChanges(cardChanges, to: player.id)
            }
        }

        if let secondary = secondaryPlayer {
            applyStatChanges(eventType.secondaryStatChanges, to: secondary.id)
        }

        addEvent(
            eventTypeID: eventType.id,
            label: eventType.label,
            title: eventTitle(for: eventType, primaryPlayer: primaryPlayer, secondaryPlayer: secondaryPlayer),
            detail: eventDetail(for: eventType, secondaryPlayer: secondaryPlayer, shotOnTarget: shotOnTarget, cardType: cardType)
        )

        if sport.supportsPeriods, eventType.id == "setWon" || eventType.id == "setLost" {
            advancePeriodAndResume()
        }
    }

    func recordHoleScore(player: Player, holeIndex: Int, strokes: Int, putts: Int?) {
        guard holeCount > 0 else { return }
        let clampedIndex = max(0, min(holeIndex, holeCount - 1))
        pushUndo()

        var scores = playerHoleScores[player.id, default: Array(repeating: 0, count: holeCount)]
        let previousScore = scores[clampedIndex]
        scores[clampedIndex] = strokes
        playerHoleScores[player.id] = scores

        if let putts {
            var puttScores = playerHolePutts[player.id, default: Array(repeating: 0, count: holeCount)]
            let previousPutts = puttScores[clampedIndex]
            puttScores[clampedIndex] = putts
            playerHolePutts[player.id] = puttScores
            updatePlayerStats(id: player.id) { player in
                player.incrementStat("putts", by: putts - previousPutts)
            }
        }

        updatePlayerStats(id: player.id) { player in
            player.incrementStat("strokes", by: strokes - previousScore)
            if previousScore == 0 && strokes > 0 {
                player.incrementStat("holesPlayed", by: 1)
            }
        }

        addEvent(
            eventTypeID: "holeScore",
            label: "Hole",
            title: "Hole \(clampedIndex + 1) — \(displayName(for: player))",
            detail: holeDetail(strokes: strokes, putts: putts)
        )

        if clampedIndex >= currentPeriodIndex, clampedIndex < holeCount - 1 {
            currentPeriodIndex = clampedIndex + 1
        }
    }

    private func updatePlayerStats(id: UUID, update: (inout Player) -> Void) {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return }
        var player = players[idx]
        update(&player)
        players[idx] = player
    }

    private func applyStatChanges(_ changes: [String: Int], to playerID: UUID) {
        guard !changes.isEmpty else { return }
        updatePlayerStats(id: playerID) { player in
            for (statID, delta) in changes {
                player.incrementStat(statID, by: delta)
            }
        }
    }

    private func addEvent(eventTypeID: String, label: String, title: String, detail: String?) {
        let event = MatchEvent(eventTypeID: eventTypeID, label: label, seconds: secondsElapsed, title: title, detail: detail)
        events.insert(event, at: 0)
    }

    private func resolvedPrimaryPlayer(for eventType: EventType, primaryPlayer: Player?) -> Player? {
        if let primaryPlayer {
            return primaryPlayer
        }
        if eventType.usesGoalie {
            return activeGoalkeeper()
        }
        return nil
    }

    private func eventTitle(for eventType: EventType, primaryPlayer: Player?, secondaryPlayer: Player?) -> String {
        if let player = resolvedPrimaryPlayer(for: eventType, primaryPlayer: primaryPlayer) {
            return "\(eventType.label) — \(displayName(for: player))"
        }
        return eventType.label
    }

    private func eventDetail(
        for eventType: EventType,
        secondaryPlayer: Player?,
        shotOnTarget: Bool?,
        cardType: CardType?
    ) -> String? {
        if let secondaryPlayer, eventType.secondaryPlayerOptional {
            return "Assist: \(displayName(for: secondaryPlayer))"
        }
        if let cardType {
            return cardType.rawValue
        }
        if let shotOnTarget {
            return shotOnTarget ? "On Target" : "Off Target"
        }
        return nil
    }

    func activeGoalkeeper() -> Player? {
        guard sport.supportsGoalie else { return nil }
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
        return onFieldPlayers.first(where: { $0.position == .gk }) ?? players.first(where: { $0.position == .gk })
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

    func markPlayerSecondsBaseline() {
        lastPlayerUpdateSeconds = elapsedSeconds
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

        let sample: [Player]
        switch sport.id {
        case SportCatalog.basketballID:
            fieldSize = 5
            sample = [
                Player(name: "Guard", number: 1, position: .cm),
                Player(name: "Guard", number: 2, position: .cm),
                Player(name: "Forward", number: 3, position: .cm),
                Player(name: "Forward", number: 4, position: .cm),
                Player(name: "Center", number: 5, position: .cm)
            ]
        case SportCatalog.waterPoloID:
            fieldSize = 7
            sample = [
                Player(name: "Goalie", number: 1, position: .gk),
                Player(name: "Field", number: 2, position: .cm),
                Player(name: "Field", number: 3, position: .cm),
                Player(name: "Field", number: 4, position: .cm),
                Player(name: "Field", number: 5, position: .cm),
                Player(name: "Field", number: 6, position: .cm),
                Player(name: "Field", number: 7, position: .cm)
            ]
        case SportCatalog.volleyballID:
            fieldSize = 6
            sample = [
                Player(name: "Setter", number: 1, position: .cm),
                Player(name: "Outside", number: 2, position: .cm),
                Player(name: "Outside", number: 3, position: .cm),
                Player(name: "Middle", number: 4, position: .cm),
                Player(name: "Middle", number: 5, position: .cm),
                Player(name: "Libero", number: 6, position: .cm)
            ]
        case SportCatalog.tennisID:
            fieldSize = 2
            sample = [
                Player(name: "Player A", number: 1, position: .cm),
                Player(name: "Player B", number: 2, position: .cm)
            ]
        case SportCatalog.golfID:
            fieldSize = 1
            sample = [
                Player(name: "Golfer", number: 1, position: .cm)
            ]
        default:
            fieldSize = 11
            sample = [
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
        }

        players = sample.map { player in
            var updated = player
            updated.statValues = Dictionary(uniqueKeysWithValues: sport.statSchema.map { ($0.id, 0) })
            return updated
        }
        let depth = Team.goalkeeperDepthIDs(from: sample)
        goalkeeperDepthIDs = [depth.primary, depth.secondary, depth.third].compactMap { $0 }
        onFieldLineupIDs = sample.map { $0.id }
        onFieldIDs = Set(sample.map { $0.id })
        configureHoleTracking()
    }

    private func applyPeriodScore(delta: Int, isOpponent: Bool) {
        guard !periodScores.isEmpty else { return }
        let index = min(max(currentPeriodIndex, 0), periodScores.count - 1)
        var score = periodScores[index]
        if isOpponent {
            score.opponentScore += delta
        } else {
            score.teamScore += delta
        }
        periodScores[index] = score
    }

    private func resolvedPeriods(for sport: any SportDefinition, template: GameTemplate?) -> [PeriodDefinition] {
        guard sport.supportsPeriods else { return [] }
        var periods = sport.periods
        if let count = template?.periodCountOverrides {
            if count <= periods.count {
                periods = Array(periods.prefix(count))
            } else if let last = periods.last {
                let startIndex = periods.count + 1
                let extra = (startIndex...count).map { index in
                    PeriodDefinition(name: "Period \(index)", duration: last.duration, maxCount: last.maxCount)
                }
                periods.append(contentsOf: extra)
            }
        }
        if let overrides = template?.periodDurationOverrides {
            for index in 0..<min(overrides.count, periods.count) {
                let original = periods[index]
                periods[index] = PeriodDefinition(name: original.name, duration: overrides[index], maxCount: original.maxCount)
            }
        }
        return periods
    }

    private func resolvedHoleCount(for sport: any SportDefinition, template: GameTemplate?) -> Int {
        guard sport.supportsHoles else { return 0 }
        if let override = template?.periodCountOverrides {
            return override
        }
        return sport.defaultHoleCount
    }

    private func configureRosterMode() {
        guard let template = activeTemplate else { return }
        switch template.defaultRosterMode {
        case .fullRoster:
            onFieldLineupIDs = players.map(\.id)
            onFieldIDs = Set(onFieldLineupIDs)
            fieldSize = max(players.count, 1)
        case .teamDefaults:
            break
        }
    }

    private func configureHoleTracking() {
        guard holeCount > 0 else { return }
        for player in players {
            if playerHoleScores[player.id] == nil {
                playerHoleScores[player.id] = Array(repeating: 0, count: holeCount)
            }
            if playerHolePutts[player.id] == nil {
                playerHolePutts[player.id] = Array(repeating: 0, count: holeCount)
            }
        }
    }

    private func holeDetail(strokes: Int, putts: Int?) -> String {
        if let putts {
            return \"Strokes: \\(strokes) • Putts: \\(putts)\"
        }
        return \"Strokes: \\(strokes)\"
    }
}
