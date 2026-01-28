import Foundation

enum StatsDateRange: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case last7 = "Last 7 Days"
    case last30 = "Last 30 Days"
    case last90 = "Last 90 Days"
    case custom = "Custom"

    var id: String { rawValue }

    func matches(date: Date, customStart: Date, customEnd: Date) -> Bool {
        let now = Date()

        switch self {
        case .allTime:
            return true
        case .last7:
            return date >= Calendar.current.date(byAdding: .day, value: -7, to: now)!
        case .last30:
            return date >= Calendar.current.date(byAdding: .day, value: -30, to: now)!
        case .last90:
            return date >= Calendar.current.date(byAdding: .day, value: -90, to: now)!
        case .custom:
            // inclusive range
            return (date >= customStart) && (date <= customEnd)
        }
    }
}


