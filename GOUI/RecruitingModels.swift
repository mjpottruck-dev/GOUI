import Foundation

struct PlayerProfile: Codable, Hashable {
    var bio: String = ""
    var height: String = ""
    var weight: String = ""
    var gradYear: Int? = nil
    var gpa: Double? = nil
    var positions: [String] = []
    var primarySports: [String] = []
    var region: String = ""
    var highlightClipIDs: [UUID] = []
    var statsHistory: [PlayerSeasonSnapshot] = []
    var isPublic: Bool = false
    var isRecruiterVisible: Bool = false
    var publicProfileID: String = UUID().uuidString
    var lastSharedAt: Date? = nil

    var publicProfileURL: URL? {
        guard isPublic else { return nil }
        return URL(string: "https://gostats.app/p/\(publicProfileID)")
    }
}

struct PlayerSeasonSnapshot: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var seasonID: UUID? = nil
    var seasonLabel: String
    var statSummary: [String: Int]
    var notes: String = ""
}

struct RecruiterFilterState: Hashable {
    var sportID: String? = nil
    var gradYear: Int? = nil
    var region: String = ""
    var minPrimaryStat: Int = 0
}
