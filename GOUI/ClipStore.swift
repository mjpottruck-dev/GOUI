import Foundation

final class ClipStore: ObservableObject {
    @Published private(set) var recordings: [VideoRecording] = []
    @Published private(set) var clips: [Clip] = []
    @Published private(set) var clipLinks: [ClipLink] = []

    private let storageURL: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "ClipStoreQueue", qos: .utility)

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storageURL = documents.appendingPathComponent("clips.json")
        load()
    }

    struct PersistedData: Codable {
        var recordings: [VideoRecording]
        var clips: [Clip]
        var clipLinks: [ClipLink]
    }

    func load() {
        queue.async {
            guard let data = try? Data(contentsOf: self.storageURL) else { return }
            guard let decoded = try? JSONDecoder().decode(PersistedData.self, from: data) else { return }
            DispatchQueue.main.async {
                self.recordings = decoded.recordings
                self.clips = decoded.clips
                self.clipLinks = decoded.clipLinks
            }
        }
    }

    func save() {
        let payload = PersistedData(recordings: recordings, clips: clips, clipLinks: clipLinks)
        queue.async {
            guard let data = try? JSONEncoder().encode(payload) else { return }
            try? data.write(to: self.storageURL, options: [.atomic])
        }
    }

    func startRecording(gameID: UUID, fileURL: URL, startDate: Date) -> VideoRecording {
        let recording = VideoRecording(
            gameID: gameID,
            createdAt: Date(),
            filePath: fileURL.path,
            startDate: startDate,
            duration: 0,
            isFinalized: false
        )
        recordings.insert(recording, at: 0)
        save()
        return recording
    }

    func finalizeRecording(id: UUID, duration: TimeInterval) {
        guard let index = recordings.firstIndex(where: { $0.id == id }) else { return }
        recordings[index].duration = duration
        recordings[index].isFinalized = true
        save()
    }

    func addClip(_ clip: Clip, links: [ClipLink]) {
        clips.insert(clip, at: 0)
        if !links.isEmpty {
            clipLinks.append(contentsOf: links)
        }
        save()
    }

    func recordings(for gameID: UUID) -> [VideoRecording] {
        recordings.filter { $0.gameID == gameID }
    }

    func clips(for gameID: UUID) -> [Clip] {
        clips.filter { $0.gameID == gameID }
    }

    func clips(forPlayerID playerID: UUID) -> [Clip] {
        clips.filter { $0.linkedPlayerIDs.contains(playerID) }
    }

    func linkedClips(for eventID: UUID) -> [Clip] {
        let linkedClipIDs = clipLinks.filter { $0.eventID == eventID }.map { $0.clipID }
        return clips.filter { linkedClipIDs.contains($0.id) }
    }

    func recording(for id: UUID) -> VideoRecording? {
        recordings.first(where: { $0.id == id })
    }

    func recordingForEvent(_ event: MatchEvent, gameID: UUID) -> VideoRecording? {
        let matchRecordings = recordings(for: gameID)
        let eventTime = event.createdAt
        return matchRecordings.first(where: { recording in
            let liveDuration = recording.isFinalized ? recording.duration : max(recording.duration, Date().timeIntervalSince(recording.startDate))
            let end = recording.startDate.addingTimeInterval(liveDuration)
            return eventTime >= recording.startDate && eventTime <= end
        })
    }

    func clipsForGameAndPlayer(gameID: UUID, playerID: UUID) -> [Clip] {
        clips.filter { $0.gameID == gameID && $0.linkedPlayerIDs.contains(playerID) }
    }

    func totalStorageBytes() -> Int64 {
        recordings.reduce(0) { total, recording in
            let size = (try? fileManager.attributesOfItem(atPath: recording.filePath)[.size] as? NSNumber)?.int64Value ?? 0
            return total + size
        }
    }

    func deleteRecordingsNotUsedByClips(excluding activeRecordingID: UUID? = nil) {
        let usedRecordingIDs = Set(clips.map { $0.recordingID })
        var removed: [VideoRecording] = []
        recordings.removeAll { recording in
            let shouldRemove = !usedRecordingIDs.contains(recording.id) && recording.id != activeRecordingID
            if shouldRemove {
                removed.append(recording)
            }
            return shouldRemove
        }
        removed.forEach { removeFile(at: $0.fileURL) }
        save()
    }

    func deleteAllVideo(for gameID: UUID) {
        let recordingsToRemove = recordings.filter { $0.gameID == gameID }
        recordings.removeAll { $0.gameID == gameID }
        clips.removeAll { $0.gameID == gameID }
        clipLinks.removeAll { link in
            !clips.contains(where: { $0.id == link.clipID })
        }
        recordingsToRemove.forEach { removeFile(at: $0.fileURL) }
        save()
    }

    private func removeFile(at url: URL) {
        try? fileManager.removeItem(at: url)
    }
}
