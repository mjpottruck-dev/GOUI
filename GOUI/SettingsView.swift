import SwiftUI

struct SettingsView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore

    @AppStorage(DebugSettings.renderCountKey) private var renderCountsEnabled = false
    @AppStorage(DebugSettings.skipSplashKey) private var skipSplashEnabled = false

    var body: some View {
        NavigationStack {
            Form {
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
        }
    }

    private var storageString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: clipStore.totalStorageBytes())
    }
}
