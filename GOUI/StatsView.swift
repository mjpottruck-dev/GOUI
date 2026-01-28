import SwiftUI

struct StatsView: View {
    let store: MatchStore

    @State private var filters = GSMatchFilters()

    private var filtered: [MatchRecord] {
        filters.apply(to: store.archive)
    }

    var body: some View {
        List {
            Section {
                filtersUI
            }

            Section("Summary") {
                summaryRow(title: "Matches", value: "\(filtered.count)")
                summaryRow(title: "Goals For", value: "\(filtered.reduce(0) { $0 + $1.goalsFor })")
                summaryRow(title: "Goals Against", value: "\(filtered.reduce(0) { $0 + $1.goalsAgainst })")
            }

            Section("Matches") {
                if filtered.isEmpty {
                    Text("No matches found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filtered) { match in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(match.opponent.isEmpty ? "Opponent" : match.opponent)
                                    .font(.headline)
                                Spacer()
                                Text("\(match.goalsFor) - \(match.goalsAgainst)")
                                    .font(.headline)
                                    .monospacedDigit()
                            }

                            HStack(spacing: 10) {
                                Text(dateText(match.date))
                                    .foregroundStyle(.secondary)

                                Text(timeText(match.secondsElapsed))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Filters UI

    private var filtersUI: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search opponent…", text: $filters.searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)

            Picker("Range", selection: $filters.range) {
                ForEach(GSMatchRangeFilter.allCases, id: \.self) { r in
                    Text(r.title).tag(r)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Use date range", isOn: $filters.useDateRange)

            if filters.useDateRange {
                DatePicker("Start", selection: $filters.startDate, displayedComponents: .date)
                DatePicker("End", selection: $filters.endDate, displayedComponents: .date)
            }
        }
        .padding(.vertical, 6)
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    // MARK: - Helpers

    private func dateText(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }

    private func timeText(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Collision-proof filter types (prefixed with GS)

enum GSMatchRangeFilter: CaseIterable, Hashable {
    case all
    case last5
    case last10

    var title: String {
        switch self {
        case .all: return "All"
        case .last5: return "Last 5"
        case .last10: return "Last 10"
        }
    }
}

struct GSMatchFilters {
    var searchText: String = ""
    var range: GSMatchRangeFilter = .all

    var useDateRange: Bool = false
    var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    var endDate: Date = Date()

    func apply(to matches: [MatchRecord]) -> [MatchRecord] {
        var out = matches

        // Search
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let q = trimmed.lowercased()
            out = out.filter { $0.opponent.lowercased().contains(q) }
        }

        // Date range
        if useDateRange {
            let start = Calendar.current.startOfDay(for: startDate)
            let endStart = Calendar.current.startOfDay(for: endDate)
            let endExclusive = Calendar.current.date(byAdding: .day, value: 1, to: endStart) ?? endDate
            out = out.filter { $0.date >= start && $0.date < endExclusive }
        }

        // Range (count-based)
        switch range {
        case .all:
            break
        case .last5:
            out = out.safePrefix(5)
        case .last10:
            out = out.safePrefix(10)
        }

        return out
    }
}

