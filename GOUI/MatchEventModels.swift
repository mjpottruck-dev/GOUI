import Foundation

// MARK: - MatchAction (for future event flow)

struct MatchAction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var eventTypeID: String
    var seconds: Int

    // Optional links (future proof)
    var primaryPlayerID: UUID? = nil
    var secondaryPlayerID: UUID? = nil
    var isOnTarget: Bool? = nil

    init(eventTypeID: String, seconds: Int) {
        self.eventTypeID = eventTypeID
        self.seconds = seconds
    }
}

// MARK: - MatchEvent (timeline)

struct MatchEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var eventTypeID: String
    var label: String
    var seconds: Int

    var title: String
    var detail: String?

    var createdAt: Date = Date()
    var primaryPlayerID: UUID? = nil
    var secondaryPlayerID: UUID? = nil

    init(
        eventTypeID: String,
        label: String,
        seconds: Int,
        title: String,
        detail: String? = nil,
        createdAt: Date = Date(),
        primaryPlayerID: UUID? = nil,
        secondaryPlayerID: UUID? = nil
    ) {
        self.eventTypeID = eventTypeID
        self.label = label
        self.seconds = seconds
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.primaryPlayerID = primaryPlayerID
        self.secondaryPlayerID = secondaryPlayerID
    }
}
