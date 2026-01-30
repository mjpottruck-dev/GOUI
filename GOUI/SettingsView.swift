import SwiftUI

struct SettingsView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore

    @AppStorage(DebugSettings.renderCountKey) private var renderCountsEnabled = false
    @AppStorage(DebugSettings.skipSplashKey) private var skipSplashEnabled = false

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService

    @State private var showPricing = false
    @State private var showCoachTeams = false
    @State private var selectedDebugPlan: Plan = .free

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    HStack {
                        Text("Current Plan")
                        Spacer()
                        Text(subscriptionManager.currentPlan.displayName)
                            .foregroundStyle(.secondary)
                    }
                    Button("View Pricing") {
                        showPricing = true
                    }
                    if !subscriptionManager.entitlements.unlimitedExports {
                        Text("Exports used this month: \(subscriptionManager.exportsThisMonth()) / \(SubscriptionLimits.freeExportsPerMonth)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Profile") {
                    Picker("Role", selection: Binding(
                        get: { roleManager.role },
                        set: { roleManager.setRole($0) }
                    )) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    Text("Changing roles affects access. Coach and recruiter roles have restrictions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    NavigationLink("Join Club") {
                        JoinClubView()
                    }
                }

                Section("Coach Membership") {
                    if let activeCoach = membershipStore.activeCoachTeam(for: roleManager.userID),
                       let team = teamStore.teams.first(where: { $0.id == activeCoach.teamID }) {
                        HStack {
                            Text("Assigned Team")
                            Spacer()
                            Text(team.name)
                                .foregroundStyle(.secondary)
                        }
                        Button("Remove Coach Access", role: .destructive) {
                            membershipStore.updateMembership(activeCoach, role: .viewer)
                        }
                        Text("Coach Pro includes one active coach team.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No coach team assigned.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Assign Coach Team") {
                            showCoachTeams = true
                        }
                    }
                }

                Section("Video Storage") {
                    HStack {
                        Text("Used")
                        Spacer()
                        Text(storageString)
                            .foregroundStyle(.secondary)
                    }

                    Button("Delete recordings not used by clips", role: .destructive) {
                        clipStore.deleteRecordingsNotUsedByClips()
                    }
                }

                Section("Cloud Sync") {
                    Toggle("Cloud Sync", isOn: $teamStore.cloudSyncEnabled)
                        .disabled(!subscriptionManager.entitlements.rosterCloudSync)

                    HStack {
                        Text("Status")
                        Spacer()
                        if teamStore.syncStatus.isSyncing {
                            ProgressView()
                        } else {
                            Text(teamStore.syncStatus.lastSyncDate?.formatted(date: .abbreviated, time: .shortened) ?? "Not yet")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let error = teamStore.syncStatus.lastError {
                        Text("Last error: \(error)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if !subscriptionManager.entitlements.rosterCloudSync {
                        Text("Upgrade to Pro to enable roster cloud sync.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Analytics") {
                    NavigationLink("Analytics Debug") {
                        AnalyticsDebugView()
                    }
                }

                Section("Recruiting") {
                    if roleManager.role == .recruiter {
                        NavigationLink("Recruiter Portal") {
                            RecruiterPortalView(teamStore: teamStore, clipStore: clipStore)
                        }
                    } else {
                        Text("Recruiter Portal is available for recruiter roles.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Debug") {
                    Toggle("Render Count Logs", isOn: $renderCountsEnabled)
                        .onChange(of: renderCountsEnabled) { _, newValue in
                            DebugSettings.setRenderCountsEnabled(newValue)
                        }

                    #if DEBUG
                    Toggle("Skip Splash Screen", isOn: $skipSplashEnabled)
                        .onChange(of: skipSplashEnabled) { _, newValue in
                            DebugSettings.setSkipSplashEnabled(newValue)
                        }

                    Picker("Debug Plan", selection: $selectedDebugPlan) {
                        ForEach(Plan.allCases) { plan in
                            Text(plan.displayName).tag(plan)
                        }
                    }
                    .onChange(of: selectedDebugPlan) { _, newValue in
                        subscriptionManager.updatePlanForDebug(newValue)
                    }
                    #endif
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPricing) {
                PricingView()
                    .environmentObject(subscriptionManager)
            }
            .sheet(isPresented: $showCoachTeams) {
                CoachTeamAssignmentSheet(teamStore: teamStore)
                    .environmentObject(membershipStore)
                    .environmentObject(permissionService)
            }
            .onAppear {
                selectedDebugPlan = subscriptionManager.currentPlan
            }
        }
    }

    private var storageString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: clipStore.totalStorageBytes())
    }
}

private struct CoachTeamAssignmentSheet: View {
    @Bindable var teamStore: TeamStore
    @EnvironmentObject var membershipStore: TeamMembershipStore
    @EnvironmentObject var permissionService: PermissionService
    @EnvironmentObject var roleManager: RoleManager
    @Environment(\.dismiss) private var dismiss

    @State private var showLimitAlert = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(teamStore.teams) { team in
                    Button(team.name) {
                        guard permissionService.canAssignCoachRole(teamID: team.id, role: .coachManager) else {
                            showLimitAlert = true
                            return
                        }
                        if let existing = membershipStore.membershipRecord(for: team.id, userID: roleManager.userID) {
                            membershipStore.updateMembership(existing, status: .active, role: .coachManager)
                        } else {
                            membershipStore.requestJoin(teamID: team.id, userID: roleManager.userID, role: .coachManager)
                            if let pending = membershipStore.membershipRecord(for: team.id, userID: roleManager.userID) {
                                membershipStore.approveMembership(pending)
                            }
                        }
                        dismiss()
                    }
                }
            }
            .navigationTitle("Assign Coach Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Coach Team Limit", isPresented: $showLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(permissionService.coachLimitMessage())
            }
        }
    }
}
