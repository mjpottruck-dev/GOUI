import Foundation

@MainActor
final class StatKeeperRequestStore: ObservableObject {
    @Published private(set) var requests: [StatKeeperRequest] = [] {
        didSet { save() }
    }

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("stat_keeper_requests.json")
        load()
    }

    func requests(for teamID: UUID) -> [StatKeeperRequest] {
        requests.filter { $0.teamID == teamID }
    }

    func submitRequest(_ request: StatKeeperRequest) {
        requests.append(request)
    }

    func updateRequest(_ request: StatKeeperRequest, status: JoinRequestStatus, reviewerID: String?) {
        guard let idx = requests.firstIndex(where: { $0.id == request.id }) else { return }
        var updated = requests[idx]
        updated.status = status
        updated.reviewedByUserID = reviewerID
        updated.reviewedAt = Date()
        updated.updatedAt = Date()
        requests[idx] = updated
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([StatKeeperRequest].self, from: data) else {
            requests = []
            return
        }
        requests = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(requests) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
