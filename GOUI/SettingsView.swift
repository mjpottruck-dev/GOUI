import SwiftUI

struct SettingsView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore

    @AppStorage(DebugSettings.renderCountKey) private var renderCountsEnabled = false
    @AppStorage(DebugSettings.skipSplashKey) private var skipSplashEnabled = false

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var roleManager: RoleManager

    @State private var showPricing = false

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

                    NavigationLink("Join Club") {
                        JoinClubView()
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
                    #endif
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPricing) {
                PricingView()
                    .environmentObject(subscriptionManager)
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
