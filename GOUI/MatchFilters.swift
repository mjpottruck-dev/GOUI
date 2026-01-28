import Foundation

struct MatchFilters: Equatable {
    var searchText: String = ""

    var range: MatchRangeFilter = .all

    // ✅ non-optional dates to avoid Binding<Date?> vs Binding<Date> errors
    var seasonStart: Date = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 8, day: 1)) ?? Date()
    var seasonEnd: Date = Date()

    var useDateRange: Bool = false
    var rangeStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var rangeEnd: Date = Date()
}

