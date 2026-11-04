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
    @Namespace private var tabNS

    var body: some View {
        VStack(spacing: 0) {
            // Content
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

            // Custom tab bar
            VStack(spacing: 0) {
                Rectangle()
                    .fill(GoStatsTheme.divider)
                    .frame(height: GoStatsTheme.dividerWidth)

                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        tabButton(tab)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(height: 56)
                .background(Color.white)
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    private func tabButton(_ tab: Tab) -> some View {
        let isActive = selected == tab
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GoStatsTheme.surface)
                            .matchedGeometryEffect(id: "tabPill", in: tabNS)
                            .frame(width: 56, height: 32)
                    }
                    Image(systemName: tabIcon(tab))
                        .font(.system(size: 22))
                        .foregroundStyle(isActive ? GoStatsTheme.textPrimary : GoStatsTheme.textMuted)
                }
                .frame(height: 32)

                Text(tabLabel(tab))
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? GoStatsTheme.textPrimary : GoStatsTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
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
