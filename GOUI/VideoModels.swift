import Foundation

struct VideoRecording: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var gameID: UUID
    var createdAt: Date
    var filePath: String
    var startDate: Date
    var duration: TimeInterval
    var isFinalized: Bool = true

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}

struct Clip: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var gameID: UUID
    var recordingID: UUID
    var startOffset: TimeInterval
    var endOffset: TimeInterval
    var createdAt: Date
    var title: String
    var linkedEventIDs: [UUID]
    var linkedPlayerIDs: [UUID]
}

struct ClipLink: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var clipID: UUID
    var eventID: UUID
    var playerID: UUID?
}
