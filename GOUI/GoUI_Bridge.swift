import Foundation

typealias Match = MatchRecord

extension MatchStore {
    // This is the list the Archive/Stats screens read from
    var archivedMatches: [Match] {
        archive
    }
}

