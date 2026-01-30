import Foundation
import SwiftUI

enum AnalyticsEventName: String, Codable, CaseIterable {
    case appOpen = "app_open"
    case createdTeam = "created_team"
    case startedGame = "started_game"
    case loggedEvent = "logged_event"
    case createdClip = "created_clip"
    case tappedExport = "tapped_export"
    case upgradeViewed = "upgrade_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
}

struct AnalyticsEvent: Codable, Identifiable {
    let id: UUID
    let name: AnalyticsEventName
    let createdAt: Date
    let metadata: [String: String]?

    init(name: AnalyticsEventName, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.metadata = metadata
    }
}

final class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published private(set) var events: [AnalyticsEvent] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "AnalyticsService", qos: .utility)

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("analytics_log.json")
        load()
    }

    func log(_ name: AnalyticsEventName, metadata: [String: String]? = nil) {
        let event = AnalyticsEvent(name: name, metadata: metadata)
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            self.persist(events: self.events)
        }
    }

    func eventCounts() -> [AnalyticsEventName: Int] {
        Dictionary(grouping: events, by: { $0.name }).mapValues { $0.count }
    }

    func exportLogURL() -> URL? {
        do {
            let data = try JSONEncoder().encode(events)
            let exportURL = fileURL.deletingLastPathComponent().appendingPathComponent("analytics_export.json")
            try data.write(to: exportURL, options: [.atomic])
            return exportURL
        } catch {
            return nil
        }
    }

    private func load() {
        queue.async {
            guard let data = try? Data(contentsOf: self.fileURL) else { return }
            guard let decoded = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) else { return }
            DispatchQueue.main.async {
                self.events = decoded
            }
        }
    }

    private func persist(events: [AnalyticsEvent]) {
        queue.async {
            if let data = try? JSONEncoder().encode(events) {
                try? data.write(to: self.fileURL, options: [.atomic])
            }
        }
    }
}
