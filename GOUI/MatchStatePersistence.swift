import Foundation

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
    }

    static func save(from store: MatchSessionStore, teamName: String, opponent: String) {
        store.refreshElapsedFromClock()
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
            currentSeasonID: store.currentSeasonID
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
