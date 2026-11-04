import Foundation

/// A single correction rule stored when a coach manually adjusts positions
/// after a line change within 2 minutes.
struct CorrectionRule: Codable, Identifiable {
    var id: UUID = UUID()
    let playerIDs: [UUID]
    let originalPositions: [String: String]   // playerID string → position rawValue
    let correctedPositionStrings: [String: String] // playerID string → corrected position rawValue
    let matchMinute: Int
    let scoreDiff: Int  // goalsFor - goalsAgainst at time of correction
    let half: Int       // 1 or 2
    let createdAt: Date

    var correctedPositions: [UUID: Position] {
        var result: [UUID: Position] = [:]
        for (key, value) in correctedPositionStrings {
            if let uuid = UUID(uuidString: key), let pos = Position(rawValue: value) {
                result[uuid] = pos
            }
        }
        return result
    }

    init(id: UUID = UUID(), playerIDs: [UUID], originalPositions: [String: String], correctedPositions: [UUID: Position], matchMinute: Int, scoreDiff: Int, half: Int, createdAt: Date = Date()) {
        self.id = id
        self.playerIDs = playerIDs
        self.originalPositions = originalPositions
        self.correctedPositionStrings = Dictionary(uniqueKeysWithValues: correctedPositions.map { ($0.key.uuidString, $0.value.rawValue) })
        self.matchMinute = matchMinute
        self.scoreDiff = scoreDiff
        self.half = half
        self.createdAt = createdAt
    }
}

/// Persists and retrieves coach correction rules.
final class CorrectionMemoryStore {
    static let shared = CorrectionMemoryStore()

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("correction_rules.json")
    }()

    private var rules: [CorrectionRule] = []

    private init() {
        load()
    }

    func allRules() -> [CorrectionRule] {
        rules
    }

    /// Find correction rules that involve the given set of player IDs.
    func matchingRules(for playerIDs: Set<UUID>) -> [CorrectionRule] {
        rules.filter { rule in
            let rulePlayerSet = Set(rule.playerIDs)
            return !rulePlayerSet.isDisjoint(with: playerIDs)
        }
    }

    func addRule(_ rule: CorrectionRule) {
        rules.append(rule)
        // Keep only last 100 rules to prevent unbounded growth
        if rules.count > 100 {
            rules = Array(rules.suffix(100))
        }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(rules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[CorrectionMemory] Save failed: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            rules = try JSONDecoder().decode([CorrectionRule].self, from: data)
        } catch {
            print("[CorrectionMemory] Load failed: \(error)")
            rules = []
        }
    }
}
