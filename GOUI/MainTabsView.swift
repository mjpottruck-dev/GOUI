// CODEX SYNC TEST
import SwiftUI

struct MainTabsView: View {

    @ObservedObject var store: MatchStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @Binding var incomingRosterURL: URL?
    var onMatchSaved: (() -> Void)? = nil

    enum Tab: Int, CaseIterable { case match, roster, stats, settings }
    @State private var selected: Tab = .match

    var body: some View {
        Group {
            switch selected {
            case .match:
                NavigationStack { MatchView(teamStore: teamStore, teamID: teamID, onMatchSaved: onMatchSaved) }
            case .roster:
                NavigationStack { TeamRosterView(teamStore: teamStore, teamID: teamID, incomingRosterURL: $incomingRosterURL) }
            case .stats:
                NavigationStack { StatsView(teamStore: teamStore, teamID: teamID) }
            case .settings:
                NavigationStack { SettingsView(teamStore: teamStore) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Floating Liquid Glass bar; content scrolls underneath it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GlassTabBar(
                items: Tab.allCases.map { GlassTabBar<Tab>.Item(tab: $0, title: tabLabel($0), icon: tabIcon($0)) },
                selected: $selected
            )
        }
        .ignoresSafeArea(.keyboard)
    }

    private func tabIcon(_ tab: Tab) -> String {
        switch tab {
        case .match: return "soccerball"
        case .roster: return "person.3"
        case .stats: return "chart.bar"
        case .settings: return "gearshape"
        }
    }

    private func tabLabel(_ tab: Tab) -> String {
        switch tab {
        case .match: return "Match"
        case .roster: return "Roster"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }
}
