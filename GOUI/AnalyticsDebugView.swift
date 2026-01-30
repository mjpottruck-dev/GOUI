import SwiftUI

struct AnalyticsDebugView: View {
    @EnvironmentObject var analytics: AnalyticsService

    @State private var sharePayload: ShareSheetPayload? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Event Counts") {
                    ForEach(AnalyticsEventName.allCases, id: \.self) { name in
                        HStack {
                            Text(name.rawValue)
                            Spacer()
                            Text("\(analytics.eventCounts()[name, default: 0])")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Recent Events") {
                    ForEach(analytics.events.prefix(20)) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.name.rawValue)
                                .font(.headline)
                            Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let metadata = event.metadata, !metadata.isEmpty {
                                Text(metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button("Export analytics log") {
                        if let url = analytics.exportLogURL() {
                            sharePayload = ShareSheetPayload(items: [url])
                        }
                    }
                }
            }
            .navigationTitle("Analytics Debug")
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }
}
