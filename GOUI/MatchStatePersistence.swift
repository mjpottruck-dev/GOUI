import Foundation

/// Crash-safe storage for the match currently in progress.
///
/// The live match lives in memory in `MatchSessionStore`. If iOS kills the app
/// mid-game (low memory, crash, swipe-up), everything not saved here is lost.
/// `MatchSessionStore.persist()` writes this after every event, sub, undo,
/// clock change and when the app goes to the background; the root view
/// restores it on launch.
enum MatchStatePersistence {
    private static let key = "goui.inProgressMatch"

    struct PersistedState: Codable {
        let goalsFor: Int
        let goalsAgainst: Int
        let elapsedSeconds: Int
        let hasSplitHalf: Bool
        let isActive: Bool
        let teamName: String
        let opponentName: String
        let events: [MatchEvent]
        let fieldSize: Int
        let currentTeamID: UUID?
        let currentSeasonID: UUID?

        // Added so a restored match keeps per-player minutes, stats and lineup.
        // Optional so any state saved by an older build still decodes.
        var players: [Player]? = nil
        var onFieldIDs: [UUID]? = nil
        var onFieldLineupIDs: [UUID]? = nil
        var formation: Formation? = nil
        var goalkeeperDepthIDs: [UUID]? = nil
        var wasRunning: Bool? = nil
        var savedAt: Date? = nil
    }

    static func save(from store: MatchSessionStore, teamName: String, opponent: String) {
        let state = PersistedState(
            goalsFor: store.goalsFor,
            goalsAgainst: store.goalsAgainst,
            elapsedSeconds: store.elapsedSeconds,
            hasSplitHalf: store.hasSplitHalf,
            isActive: store.isActive,
            teamName: teamName,
            opponentName: opponent,
            events: store.events,
            fieldSize: store.fieldSize,
            currentTeamID: store.currentTeamID,
            currentSeasonID: store.currentSeasonID,
            players: store.players,
            onFieldIDs: Array(store.onFieldIDs),
            onFieldLineupIDs: store.onFieldLineupIDs,
            formation: store.formation,
            goalkeeperDepthIDs: store.goalkeeperDepthIDs,
            wasRunning: store.isRunning,
            savedAt: Date()
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func restore() -> PersistedState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PersistedState.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func hasInProgressMatch() -> Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }
}
