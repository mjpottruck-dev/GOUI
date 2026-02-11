import Foundation

extension MatchRecord {

    private func sum(_ keyPath: KeyPath<PlayerStatLine, Int>) -> Int {
        playerStats.values.reduce(0) { $0 + $1[keyPath: keyPath] }
    }

    var totalShots: Int { sum(\.shots) }
    var totalShotsOnTarget: Int { sum(\.shotsOnTarget) }
    var totalSaves: Int { sum(\.saves) }
    var totalPkSaved: Int { sum(\.pkSaved) }

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

