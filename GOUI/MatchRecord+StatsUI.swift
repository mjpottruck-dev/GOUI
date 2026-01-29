import Foundation

extension MatchRecord {

    private func sum(_ keyPath: KeyPath<PlayerStatLine, Int>) -> Int {
        playerStats.values.reduce(0) { $0 + $1[keyPath: keyPath] }
    }

    private func sum(statID: String) -> Int {
        playerStats.values.reduce(0) { $0 + $1.value(for: statID) }
    }

    var totalShots: Int { sum(statID: "shots") }
    var totalShotsOnTarget: Int { sum(statID: "shotsOnTarget") }
    var totalSaves: Int { sum(statID: "saves") }
    var totalPkSaved: Int { sum(statID: "pkSaved") }

    var conversionPercent: Double {
        guard totalShots > 0 else { return 0 }
        return (Double(goalsFor) / Double(totalShots)) * 100.0
    }

    var conversionText: String {
        "\(Int(conversionPercent.rounded()))%"
    }

    var minutesPlayed: Int {
        secondsElapsed / 60
    }

    var timePlayedText: String {
        let m = secondsElapsed / 60
        let s = secondsElapsed % 60
        return String(format: "%02d:%02d", m, s)
    }
}
