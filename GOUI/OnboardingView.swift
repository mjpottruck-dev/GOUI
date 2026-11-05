import SwiftUI

/// First-run welcome. Shown once to new coaches (no real team yet), then the
/// home screen's guided tour takes over.
struct OnboardingView: View {
    static let completedKey = "onboarding_completed"

    var teamStore: TeamStore
    /// Called with the new team's ID, or nil if the coach chose the sample team.
    var onFinish: (UUID?) -> Void

    @State private var page = 0
    @State private var showCreateTeam = false
    @State private var createdTeamID: UUID? = nil

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    startPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                pageDots
                    .padding(.bottom, 16)

                bottomButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showCreateTeam, onDismiss: {
            // Finish only after the team sheet has closed.
            if let id = createdTeamID { finish(with: id) }
        }) {
            CreateTeamView(teamStore: teamStore) { newTeamID in
                createdTeamID = newTeamID
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(GoStatsTheme.textPrimary)
                    .frame(width: 104, height: 104)
                Image(systemName: "soccerball")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
            }
            Text("GoalStats")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text("Live stats, subs and playing time for youth soccer coaches. Right from the sideline.")
                .font(.system(size: 17))
                .foregroundStyle(GoStatsTheme.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var featuresPage: some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer()
            Text("How it works")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            feature("stopwatch", "Run the match",
                    "Start the clock, then tap Goal, Shot, Card or Save and the player. Every player's minutes count automatically.")
            feature("mic.fill", "Or just say it",
                    "Tap the mic and say \"goal seven, assist ten\". Hands stay free for coaching.")
            feature("arrow.triangle.2.circlepath", "Fair subs",
                    "Swap players or a whole line, and get nudges when someone is due on.")
            feature("sparkles", "Instant recaps",
                    "AI summaries for each game and the season, plus PDF and MaxPreps exports.")
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var startPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 52))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text("Set up your team")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text("Add your team name, field size and players. Snap a photo of a roster sheet and GoalStats fills it in for you.")
                .font(.system(size: 16))
                .foregroundStyle(GoStatsTheme.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("Takes about 2 minutes.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(GoStatsTheme.textMuted)
            Spacer()
            Spacer()
        }
    }

    private func feature(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(GoStatsTheme.textPrimary))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(GoStatsTheme.textPrimary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Controls

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == page ? GoStatsTheme.textPrimary : GoStatsTheme.textMuted.opacity(0.4))
                    .frame(width: i == page ? 22 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: page)
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 14) {
            Button {
                Haptics.light()
                if page < 2 {
                    page += 1
                } else {
                    showCreateTeam = true
                }
            } label: {
                Text(page < 2 ? "Continue" : "Create My Team")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                            .fill(GoStatsTheme.textPrimary)
                    )
            }
            .buttonStyle(.plain)

            Button(page < 2 ? "Skip" : "Explore with a sample team first") {
                if page < 2 {
                    page = 2
                } else {
                    finish(with: nil)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(GoStatsTheme.textMuted)
        }
    }

    private func finish(with newTeamID: UUID?) {
        if newTeamID != nil {
            // They made a real team: the untouched sample team is just clutter now.
            for demo in teamStore.teams where demo.isDemo && demo.matches.isEmpty {
                teamStore.deleteTeam(demo)
            }
        }
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        onFinish(newTeamID)
    }
}
