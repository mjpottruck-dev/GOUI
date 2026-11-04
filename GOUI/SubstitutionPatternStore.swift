import Foundation

/// Per-player substitution profile built from match history.
struct PlayerSubProfile: Codable, Identifiable {
    var id: UUID  // playerID
    var totalSubEvents: Int = 0
    var totalSubOnMinute: Int = 0
    var positionsPlayed: [String: Int] = [:]  // position rawValue → count
    var situationCounts: [String: Int] = [:]  // "winning_1H", "losing_2H", etc.
    var replacedPlayerIDs: [UUID] = []
    var alongsidePlayerIDs: [UUID] = []

    var averageSubMinute: Int {
        guard totalSubEvents > 0 else { return 0 }
        return totalSubOnMinute / totalSubEvents
    }

    var mostCommonPosition: String? {
        positionsPlayed.max(by: { $0.value < $1.value })?.key
    }

    var isEligible: Bool {
        totalSubEvents >= 3
    }

    func situationKey(winning: Bool, drawing: Bool, losing: Bool, half: Int) -> String {
        let situation: String
        if winning { situation = "winning" }
        else if losing { situation = "losing" }
        else { situation = "drawing" }
        return "\(situation)_\(half)H"
    }

    func matchesCurrentSituation(minute: Int, winning: Bool, drawing: Bool, losing: Bool, half: Int) -> Bool {
        guard isEligible else { return false }
        let avgMin = averageSubMinute
        guard abs(minute - avgMin) <= 10 else { return false }

        let key = situationKey(winning: winning, drawing: drawing, losing: losing, half: half)
        let count = situationCounts[key, default: 0]
        // Require at least 2 occurrences in this situation
        return count >= 2
    }
}

/// Persists substitution profiles across matches.
final class SubstitutionPatternStore {
    static let shared = SubstitutionPatternStore()

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("substitution_profiles.json")
    }()

    private var profiles: [UUID: PlayerSubProfile] = [:]

    private init() {
        load()
    }

    func profile(for playerID: UUID) -> PlayerSubProfile? {
        profiles[playerID]
    }

    func allEligibleProfiles() -> [PlayerSubProfile] {
        profiles.values.filter { $0.isEligible }
    }

    /// After a match is saved, analyze its events and update player profiles.
    func analyzeMatch(_ record: MatchRecord, teamPlayers: [Player]) {
        let matchMinutes = record.secondsElapsed / 60
        guard matchMinutes > 0 else { return }

        let goalsFor = record.goalsFor
        let goalsAgainst = record.goalsAgainst

        for event in record.events {
            guard event.title.hasPrefix("Line Change") || event.title.contains("Sub"),
                  let detail = event.detail else { continue }

            let minute = event.seconds / 60
            let half = minute <= (matchMinutes / 2) ? 1 : 2
            let winning = goalsFor > goalsAgainst
            let drawing = goalsFor == goalsAgainst
            let losing = goalsFor < goalsAgainst

            // Parse "ON: Name1, Name2" from detail
            let parts = detail.components(separatedBy: " | ")
            guard parts.count == 2 else { continue }

            let onPart = parts[1].replacingOccurrences(of: "ON: ", with: "")
            let onNames = onPart.components(separatedBy: ", ")

            for name in onNames {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                // Find player by matching display name
                guard let player = teamPlayers.first(where: { playerMatchesName($0, displayName: trimmed) }) else { continue }

                var profile = profiles[player.id] ?? PlayerSubProfile(id: player.id)
                profile.totalSubEvents += 1
                profile.totalSubOnMinute += minute

                let posKey = player.position.rawValue
                profile.positionsPlayed[posKey, default: 0] += 1

                let sitKey = profile.situationKey(winning: winning, drawing: drawing, losing: losing, half: half)
                profile.situationCounts[sitKey, default: 0] += 1

                profiles[player.id] = profile
            }
        }

        save()
    }

    private func playerMatchesName(_ player: Player, displayName: String) -> Bool {
        let parts = player.name.split(separator: " ")
        let firstName = parts.first.map(String.init) ?? player.name
        if firstName == displayName { return true }
        if let last = parts.dropFirst().first {
            let shortName = "\(firstName) \(String(last.prefix(1)))"
            if shortName == displayName { return true }
        }
        return player.name == displayName
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(Array(profiles.values))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[SubPatterns] Save failed: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let arr = try JSONDecoder().decode([PlayerSubProfile].self, from: data)
            profiles = Dictionary(uniqueKeysWithValues: arr.map { ($0.id, $0) })
        } catch {
            print("[SubPatterns] Load failed: \(error)")
            profiles = [:]
        }
    }
}
