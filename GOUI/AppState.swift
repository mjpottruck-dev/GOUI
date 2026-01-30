import Foundation

enum AppTab: Hashable {
    case home
    case team
    case game
    case schedule
    case stats
    case chat
    case more
    case search
    case players
    case teams
}

final class AppState: ObservableObject {
    @Published var currentTeamID: UUID? {
        didSet {
            UserDefaults.standard.set(currentTeamID?.uuidString, forKey: currentTeamKey)
        }
    }

    @Published var selectedTab: AppTab = .home

    private let currentTeamKey = "app.currentTeamID"

    init() {
        if let stored = UserDefaults.standard.string(forKey: currentTeamKey),
           let id = UUID(uuidString: stored) {
            currentTeamID = id
        }
    }
}
