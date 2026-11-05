import SwiftUI

struct SettingsView: View {
    @Bindable var teamStore: TeamStore

    @AppStorage(DebugSettings.renderCountKey) private var renderCountsEnabled = false
    @AppStorage(DebugSettings.skipSplashKey) private var skipSplashEnabled = false
    @AppStorage(SettingsKeys.maxPrepsTeamID) private var maxPrepsTeamID: String = ""
    @AppStorage("substitution_suggestions_enabled") private var subSuggestionsEnabled = true
    @AppStorage("anthropic_api_key") private var anthropicAPIKey: String = ""
    @AppStorage(Haptics.enabledKey) private var hapticsEnabled = true
    @AppStorage(Haptics.intensityKey) private var hapticsIntensity = 0.8
    @State private var tourResetConfirmed = false

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Haptics
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("HAPTICS")

                            VStack(spacing: 0) {
                                Toggle("Vibration on taps", isOn: $hapticsEnabled)
                                    .font(.system(size: 15))
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 14)
                                    .onChange(of: hapticsEnabled) { _, on in
                                        if on { Haptics.medium() }
                                    }

                                if hapticsEnabled {
                                    Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Strength")
                                            .font(.system(size: 15))
                                            .foregroundStyle(GoStatsTheme.textPrimary)
                                        HStack(spacing: 10) {
                                            Image(systemName: "iphone.radiowaves.left.and.right")
                                                .font(.system(size: 12))
                                                .foregroundStyle(GoStatsTheme.textMuted)
                                            Slider(value: $hapticsIntensity, in: 0.2...1.0) { editing in
                                                if !editing { Haptics.medium() } // feel the new strength
                                            }
                                            .tint(GoStatsTheme.textPrimary)
                                            Image(systemName: "iphone.radiowaves.left.and.right")
                                                .font(.system(size: 17))
                                                .foregroundStyle(GoStatsTheme.textPrimary)
                                        }
                                    }
                                    .padding(.horizontal, GoStatsTheme.cardPadding)
                                    .padding(.vertical, 12)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }

                        // Help
                        VStack(alignment: .leading, spacing: 8) {
                            GoStatsTheme.sectionHeader("HELP")

                            VStack(spacing: 0) {
                                Button {
                                    TourFlags.resetAll()
                                    tourResetConfirmed = true
                                    Haptics.light()
                                } label: {
                                    HStack {
                                        Text("Replay App Tour")
                                            .font(.system(size: 15))
                                            .foregroundStyle(GoStatsTheme.textPrimary)
                                        Spacer()
                                        Text(tourResetConfirmed ? "Shows on next visit" : "")
                                            .font(.system(size: 13))
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                        Image(systemName: "questionmark.circle")
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, GoStatsTheme.cardPadding)
                                .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }

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

                        // Cloud Sync — debug builds only until multi-device sync is finished (v1.1).
                        #if DEBUG
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
                        #endif

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

                        // Debug — not shown in App Store builds
                        #if DEBUG
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

                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                Button("Show Onboarding Again") {
                                    TourFlags.resetAll()
                                    UserDefaults.standard.set(false, forKey: OnboardingView.completedKey)
                                }
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, GoStatsTheme.cardPadding)
                                .padding(.vertical, 14)
                                #endif
                            }
                            .background(
                                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                            )
                        }
                        #endif
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
