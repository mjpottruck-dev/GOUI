import Foundation

struct HighlightReel: Identifiable, Hashable {
    let id: UUID
    let title: String
    let clipIDs: [UUID]
    let totalDuration: TimeInterval

    init(id: UUID = UUID(), title: String, clipIDs: [UUID], totalDuration: TimeInterval) {
        self.id = id
        self.title = title
        self.clipIDs = clipIDs
        self.totalDuration = totalDuration
    }
}

struct HighlightReelGenerator {
    let minimumDuration: TimeInterval = 120
    let maximumDuration: TimeInterval = 180

    func generateReel(from clips: [Clip], title: String) -> HighlightReel? {
        let ranked = clips.sorted { lhs, rhs in
            if lhs.linkedEventIDs.count == rhs.linkedEventIDs.count {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.linkedEventIDs.count > rhs.linkedEventIDs.count
        }

        var selected: [Clip] = []
        var total: TimeInterval = 0

        for clip in ranked {
            let duration = max(clip.endOffset - clip.startOffset, 0)
            guard duration > 0 else { continue }
            if total + duration > maximumDuration && total >= minimumDuration {
                break
            }
            selected.append(clip)
            total += duration
            if total >= maximumDuration {
                break
            }
        }

        guard total > 0 else { return nil }
        return HighlightReel(title: title, clipIDs: selected.map { $0.id }, totalDuration: total)
    }
}
