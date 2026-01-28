import Foundation

enum MatchRangeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case last5 = "Last 5"
    case last10 = "Last 10"
    case season = "This Season"
    case custom = "Custom Range"

    var id: String { rawValue }
}

