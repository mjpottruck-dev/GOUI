import ActivityKit
import Foundation

struct MatchActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var homeScore: Int
        var awayScore: Int
        var minute: String
        var half: String
        var teamName: String
        var opponentName: String
        var lastEvent: String
    }

    var matchID: String
}
