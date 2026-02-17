import CoreGraphics

// Legacy type aliases kept to preserve compatibility with older views/files.
typealias Roster = Team
typealias RosterStore = TeamStore
typealias MatchViewModel = MatchStore

final class MatchPersistenceManager {
    static let shared = MatchPersistenceManager()
    private init() {}
}

typealias RosterShareManager = RosterProximityShareService

// Legacy spacing/radius namespaces preserved for older UI code.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let s: CGFloat = GoStatsTheme.s8
    static let sm: CGFloat = GoStatsTheme.s8
    static let m: CGFloat = GoStatsTheme.s12
    static let md: CGFloat = GoStatsTheme.s12
    static let l: CGFloat = GoStatsTheme.s16
    static let lg: CGFloat = GoStatsTheme.s16
    static let xl: CGFloat = GoStatsTheme.s20
    static let xxl: CGFloat = GoStatsTheme.s24
}

enum Radii {
    static let sm: CGFloat = 10
    static let md: CGFloat = GoStatsTheme.rChip
    static let lg: CGFloat = GoStatsTheme.rButton
    static let xl: CGFloat = GoStatsTheme.rCard
    static let card: CGFloat = GoStatsTheme.rCard
    static let button: CGFloat = GoStatsTheme.rButton
    static let chip: CGFloat = GoStatsTheme.rChip
}
