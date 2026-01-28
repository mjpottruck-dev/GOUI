import SwiftUI

struct ArchiveView: View {

    // New way (preferred)
    @EnvironmentObject private var envStore: MatchStore

    // Old way (if MainTabsView passes store:)
    private let passedStore: MatchStore?

    init() {
        self.passedStore = nil
    }

    init(store: MatchStore) {
        self.passedStore = store
    }

    private var store: MatchStore {
        passedStore ?? envStore
    }

    @State private var filters = MatchFilters()
    @State private var showFiltersSheet = false

    private var sortedAll: [MatchRecord] {
        store.archive.sorted { $0.date > $1.date }
    }

    private var filtered: [MatchRecord] {
        var items = sortedAll

        // Search by opponent
        if !filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let q = filters.searchText.lowercased()
            items = items.filter { $0.opponent.lowercased().contains(q) }
        }

        // Range filter
        switch filters.range {
        case .all:
            break
        case .last5:
            items = items.safePrefix(5)
        case .last10:
            items = items.safePrefix(10)
        case .season:
            items = items.filter { $0.date >= filters.seasonStart && $0.date <= filters.seasonEnd }
        case .custom:
            items = items.filter { $0.date >= filters.rangeStart && $0.date <= filters.rangeEnd }
        }

        return items
    }

    var body: some View {
        List {
            Section { searchBar }

            Section(header: headerRow) {
                if filtered.isEmpty {
                    Text("No matches found.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 10)
                } else {
                    ForEach(filtered) { match in
                        MatchRow(match: match)
                    }
                    .onDelete { offsets in
                        store.deleteArchived(at: offsets, from: filtered)
                    }
                }
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFiltersSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFiltersSheet) {
            ArchiveFiltersSheet(filters: $filters)
        }
    }

    // MARK: - UI

    private var headerRow: some View {
        HStack {
            Text("\(filtered.count) matches")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            if filters.range != .all || !filters.searchText.isEmpty {
                Button("Clear") {
                    filters = MatchFilters()
                }
                .font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search opponent…", text: $filters.searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)

            if !filters.searchText.isEmpty {
                Button {
                    filters.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Row

private struct MatchRow: View {
    let match: MatchRecord

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: match.date)
    }

    private var scoreText: String {
        "\(match.goalsFor) – \(match.goalsAgainst)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(match.opponent.isEmpty ? "Opponent" : match.opponent)
                    .font(.headline)

                Spacer()

                Text(scoreText)
                    .font(.headline)
                    .monospacedDigit()
            }

            HStack {
                Text(dateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if match.secondsElapsed > 0 {
                    Text(secondsToTime(match.secondsElapsed))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func secondsToTime(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Filters Sheet

private struct ArchiveFiltersSheet: View {
    @Binding var filters: MatchFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Range") {
                    Picker("Show", selection: $filters.range) {
                        ForEach(MatchRangeFilter.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if filters.range == .season {
                    Section("Season Dates") {
                        DatePicker("Start", selection: $filters.seasonStart, displayedComponents: .date)
                        DatePicker("End", selection: $filters.seasonEnd, displayedComponents: .date)
                    }
                }

                if filters.range == .custom {
                    Section("Custom Range") {
                        DatePicker("From", selection: $filters.rangeStart, displayedComponents: .date)
                        DatePicker("To", selection: $filters.rangeEnd, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

