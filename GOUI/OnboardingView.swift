import SwiftUI

struct OnboardingView: View {
    @Bindable var teamStore: TeamStore

    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var clubStore: ClubStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @Environment(\.dismiss) private var dismiss

    @State private var pageIndex = 0
    @State private var selectedRole: UserRole = .familyMember
    @State private var selectedTeams: Set<UUID> = []
    @State private var clubName: String = ""
    @State private var inviteCode: String = ""
    @State private var statusMessage: String? = nil
    @State private var showCreateTeam = false
    @State private var showPricing = false

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                TabView(selection: $pageIndex) {
                    roleStep.tag(0)
                    teamStep.tag(1)
                    proStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        finishOnboarding()
                    }
                }
            }
            .sheet(isPresented: $showCreateTeam) {
                CreateTeamView(teamStore: teamStore) { teamID in
                    selectedTeams.insert(teamID)
                }
            }
            .sheet(isPresented: $showPricing) {
                PricingView()
                    .environmentObject(subscriptionManager)
            }
            .onAppear {
                selectedRole = roleManager.role
                selectedTeams = Set(roleManager.profile?.affiliatedTeamIDs ?? [])
            }
        }
    }

    private var roleStep: some View {
        VStack(spacing: 20) {
            header(title: "Choose your role", subtitle: "We’ll tailor GoStats to how you use it.")

            ForEach(UserRole.allCases) { role in
                Button {
                    selectedRole = role
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(role.displayName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(role.permissionsSummary)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                        Spacer()
                        Image(systemName: selectedRole == role ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedRole == role ? GoStatsTheme.primary : GoStatsTheme.text2)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            nextButton(title: "Continue") {
                pageIndex = 1
            }
        }
        .padding(20)
    }

    private var teamStep: some View {
        VStack(spacing: 16) {
            header(title: "Pick your teams", subtitle: "Select or create your main team to get started.")

            if teamStore.teams.isEmpty {
                UpgradePromptView(
                    title: "No teams yet",
                    message: "Create your first team to unlock match tracking.",
                    buttonTitle: "Create Team"
                ) {
                    showCreateTeam = true
                }
            } else {
                teamSelectionList
            }

            if selectedRole == .familyMember {
                inviteSection
            }

            Spacer()

            VStack(spacing: 10) {
                nextButton(title: "Continue") {
                    pageIndex = 2
                }
                Button("Back") {
                    pageIndex = 0
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            }
        }
        .padding(20)
    }

    private var proStep: some View {
        VStack(spacing: 16) {
            header(title: "Go Pro", subtitle: "Unlock full exports, analytics, and highlights.")

            LiquidGlassContainer(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Unlimited exports", systemImage: "tray.and.arrow.up")
                    Label("Advanced analytics", systemImage: "chart.line.uptrend.xyaxis")
                    Label("Player highlights", systemImage: "film")
                    Label("Cloud roster sync", systemImage: "icloud")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
            }

            Button {
                showPricing = true
            } label: {
                Text("See Pricing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(GoStatsTheme.primary)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 10) {
                nextButton(title: "Finish") {
                    finishOnboarding()
                }
                Button("Back") {
                    pageIndex = 1
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            }
        }
        .padding(20)
    }

    private var teamSelectionList: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Teams")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                ForEach(teamStore.teams) { team in
                    Button {
                        if selectedTeams.contains(team.id) {
                            selectedTeams.remove(team.id)
                        } else {
                            selectedTeams.insert(team.id)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)
                                Text(SportCatalog.sport(for: team.sportID).displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                            Spacer()
                            Image(systemName: selectedTeams.contains(team.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedTeams.contains(team.id) ? GoStatsTheme.primary : GoStatsTheme.text2)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showCreateTeam = true
                } label: {
                    Label("Create Team", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var inviteSection: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Invite Code")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                TextField("Enter club invite code", text: $inviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                if let statusMessage {
                    Text(statusMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
                Button("Join Club") {
                    handleInvite()
                }
                .font(.system(size: 13, weight: .semibold))
            }
        }
    }

    private var clubSection: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Club Setup")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                TextField("Club name", text: $clubName)
                Text("Club admins can manage multiple teams and billing.")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GoStatsTheme.text2)
        }
    }

    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(GoStatsTheme.primary)
                )
        }
        .buttonStyle(.plain)
    }

    private func handleInvite() {
        let trimmed = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        if roleManager.profile == nil {
            roleManager.setRole(selectedRole)
        }
        guard let profile = roleManager.profile else { return }
        if let result = clubStore.joinClub(with: trimmed, userID: profile.userID) {
            roleManager.setRole(result.role)
            roleManager.updateClub(result.club.id)
            statusMessage = "Joined \(result.club.name)."
        } else {
            statusMessage = "Invite code not recognized."
        }
    }

    private func finishOnboarding() {
        roleManager.setRole(selectedRole)
        roleManager.updateAffiliatedTeams(Array(selectedTeams))

        roleManager.completeOnboarding()
        dismiss()
    }
}
