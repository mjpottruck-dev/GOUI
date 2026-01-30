import Foundation

final class AppState: ObservableObject {
    @Published var currentTeamID: UUID? {
        didSet {
            UserDefaults.standard.set(currentTeamID?.uuidString, forKey: currentTeamKey)
        }
    }

    private let currentTeamKey = "app.currentTeamID"

    init() {
        if let stored = UserDefaults.standard.string(forKey: currentTeamKey),
           let id = UUID(uuidString: stored) {
            currentTeamID = id
        }
    }
}
