import Foundation

enum Plan: String, CaseIterable, Codable, Identifiable {
    case free
    case playerPro
    case coachPro
    case clubPro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .playerPro: return "Player Pro"
        case .coachPro: return "Coach Pro"
        case .clubPro: return "Club Pro"
        }
    }

    var subtitle: String {
        switch self {
        case .free: return "Starter access"
        case .playerPro: return "For families"
        case .coachPro: return "For teams"
        case .clubPro: return "For clubs"
        }
    }
}

struct Entitlements: Codable, Hashable {
    var unlimitedExports: Bool
    var advancedAnalytics: Bool
    var videoClipsUnlimited: Bool
    var clipsPerGameLimit: Int
    var playerHighlights: Bool
    var clubDashboard: Bool
    var rosterCloudSync: Bool
    var multiSportUnlocked: Bool

    static let free = Entitlements(
        unlimitedExports: false,
        advancedAnalytics: false,
        videoClipsUnlimited: false,
        clipsPerGameLimit: 3,
        playerHighlights: false,
        clubDashboard: false,
        rosterCloudSync: false,
        multiSportUnlocked: true
    )

    static let playerPro = Entitlements(
        unlimitedExports: true,
        advancedAnalytics: true,
        videoClipsUnlimited: true,
        clipsPerGameLimit: 99,
        playerHighlights: true,
        clubDashboard: false,
        rosterCloudSync: true,
        multiSportUnlocked: true
    )

    static let coachPro = Entitlements(
        unlimitedExports: true,
        advancedAnalytics: true,
        videoClipsUnlimited: true,
        clipsPerGameLimit: 99,
        playerHighlights: true,
        clubDashboard: false,
        rosterCloudSync: true,
        multiSportUnlocked: true
    )

    static let clubPro = Entitlements(
        unlimitedExports: true,
        advancedAnalytics: true,
        videoClipsUnlimited: true,
        clipsPerGameLimit: 99,
        playerHighlights: true,
        clubDashboard: true,
        rosterCloudSync: true,
        multiSportUnlocked: true
    )
}

enum SubscriptionProducts {
    static let playerProMonthly = "com.gostats.playerpro.monthly"
    static let coachProMonthly = "com.gostats.coachpro.monthly"
    static let clubProContact = "contact_sales"
}

struct SubscriptionLimits {
    static let freeExportsPerMonth = 3
}
