import SwiftUI

struct SettingsView: View {
    @Bindable var teamStore: TeamStore

    @AppStorage(DebugSettings.renderCountKey) private var renderCountsEnabled = false
    @AppStorage(DebugSettings.skipSplashKey) private var skipSplashEnabled = false
    @AppStorage(SettingsKeys.maxPrepsTeamID) private var maxPrepsTeamID: String = ""
    @AppStorage("substitution_suggestions_enabled") private var subSuggestionsEnabled = true
    @AppStorage("anthropic_api_key") private var anthropicAPIKey: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // AI Features
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("AI FEATURES")

                            VStack(spacing: 0) {
                                HStack {
                                    Text("API Key")
                                        .font(.system(size: 15))
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                    Spacer()
                                    SecureField("Anthropic API Key", text: $anthropicAPIKey)
                                        .multilineTextAlignment(.trailing)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.system(size: 15))
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                }
                                .padding(.horizontal, GoStatsTheme.cardPadding)
                                .padding(.vertical, 14)

                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                Text("Required for AI match summaries, game insights, and season reports. Get yours at console.anthropic.com")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 10)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }

                        // MaxPreps
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("MAXPREPS")

                            VStack(spacing: 0) {
                                HStack {
                                    Text("Team ID")
                                        .font(.system(size: 15))
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                    Spacer()
                                    TextField("Enter ID", text: $maxPrepsTeamID)
                                        .multilineTextAlignment(.trailing)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.system(size: 15))
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                }
                                .padding(.horizontal, GoStatsTheme.cardPadding)
                                .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }

                        // Cloud Sync
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("CLOUD SYNC")

                            VStack(spacing: 0) {
                                Toggle("Cloud Sync", isOn: $teamStore.cloudSyncEnabled)
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 14)

                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                HStack {
                                    Text("Status")
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                    Spacer()
                                    if teamStore.syncStatus.isSyncing {
                                        ProgressView()
                                    } else {
                                        Text(teamStore.syncStatus.lastSyncDate?.formatted(date: .abbreviated, time: .shortened) ?? "Not yet")
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                    }
                                }
                                .font(.system(size: 15))
                                .padding(.horizontal, GoStatsTheme.cardPadding)
                                .padding(.vertical, 14)

                                if let error = teamStore.syncStatus.lastError {
                                    Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)
                                    Text("Error: \(error)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, GoStatsTheme.cardPadding)
                                        .padding(.vertical, 10)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }

                        // Match Intelligence
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("MATCH INTELLIGENCE")

                            VStack(spacing: 0) {
                                Toggle("Substitution Suggestions", isOn: $subSuggestionsEnabled)
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 14)

                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                Text("When enabled, shows smart substitution suggestions during matches based on historical patterns.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 10)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }

                        // Debug
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("DEBUG")

                            VStack(spacing: 0) {
                                Toggle("Render Count Logs", isOn: $renderCountsEnabled)
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 14)
                                    .onChange(of: renderCountsEnabled) { _, newValue in
                                        DebugSettings.setRenderCountsEnabled(newValue)
                                    }

                                #if DEBUG
                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                Toggle("Skip Splash Screen", isOn: $skipSplashEnabled)
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 14)
                                    .onChange(of: skipSplashEnabled) { _, newValue in
                                        DebugSettings.setSkipSplashEnabled(newValue)
                                    }
                                #endif
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }
                    }
                    .padding(.horizontal, GoStatsTheme.cardMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
