import SwiftUI

struct ClubDashboardView: View {
    @EnvironmentObject var clubStore: ClubStore
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var analytics: AnalyticsService

    @Bindable var teamStore: TeamStore

    @State private var showPricing = false
    @State private var sharePayload: ShareSheetPayload? = nil

    private var club: Club? {
        guard let clubID = roleManager.profile?.affiliatedClubID else { return nil }
        return clubStore.clubs.first(where: { $0.id == clubID })
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if subscriptionManager.entitlements.clubDashboard {
                        clubHeader
                        clubStats
                        billingSection
                        teamList
                        inviteSection
                        analyticsSummary
                    } else {
                        UpgradePromptView(
                            title: "Club Dashboard",
                            message: "Club Pro unlocks multi-team analytics, exports, and billing tools.",
                            buttonTitle: "Unlock Club Pro"
                        ) {
                            showPricing = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Club Admin")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPricing) {
            PricingView()
                .environmentObject(subscriptionManager)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
    }

    private var clubHeader: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CLUB")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                Text(club?.name ?? "No Club Selected")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text("Manage teams, invitations, and reports.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private var clubStats: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("CLUB OVERVIEW")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                HStack(spacing: 10) {
                    statChip("Teams", "\(clubTeams.count)")
                    statChip("Games", "\(totalGames)")
                    statChip("Active Users", "1")
                }

                Button {
                    exportClubReport()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export club report")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(GoStatsTheme.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var teamList: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("TEAMS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                if clubTeams.isEmpty {
                    Text("No teams linked yet.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    ForEach(clubTeams, id: \.id) { team in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)
                                Text("\(team.matches.count) games")
                                    .font(.system(size: 12))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var billingSection: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("BILLING")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                Text("Plan: \(subscriptionManager.currentPlan.displayName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text("Billing management is coming soon.")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private var inviteSection: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("INVITES")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if let club {
                    inviteRow(title: "Invite Coach", code: club.inviteCodes.coachCode)
                    inviteRow(title: "Invite Admin", code: club.inviteCodes.adminCode)

                    Button {
                        clubStore.regenerateInviteCodes(for: club.id)
                    } label: {
                        Text("Regenerate codes")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Create or join a club to generate invites.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
    }

    private var analyticsSummary: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("ANALYTICS SUMMARY")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                let counts = analytics.eventCounts()
                ForEach(AnalyticsEventName.allCases, id: \.self) { name in
                    HStack {
                        Text(name.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Spacer()
                        Text("\(counts[name, default: 0])")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }
            }
        }
    }

    private func inviteRow(title: String, code: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text(code)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GoStatsTheme.text2)
            }
            Spacer()
            Button {
                sharePayload = ShareSheetPayload(items: ["\(title) code: \(code)"])
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(GoStatsTheme.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private var clubTeams: [Team] {
        guard let club else { return [] }
        return teamStore.teams.filter { club.teamIDs.contains($0.id) }
    }

    private var totalGames: Int {
        clubTeams.reduce(0) { $0 + $1.matches.count }
    }

    private func exportClubReport() {
        guard let url = analytics.exportLogURL() else { return }
        sharePayload = ShareSheetPayload(items: [url])
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }
}
