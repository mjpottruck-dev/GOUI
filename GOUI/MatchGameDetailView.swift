import SwiftUI

/// Game detail screen shown when tapping a match in the archive.
/// Shows: score header, timeline, aggregated stats (goals, assists, shots, saves, cards, subs).
struct MatchGameDetailView: View {
    let match: MatchRecord
    let team: Team

    @State private var insightText: String? = nil
    @State private var insightLoading = false
    @State private var insightError: String? = nil

    private var insightCacheKey: String { "match_insight_\(match.id.uuidString)" }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    scoreHeader
                    matchInfoCard
                    goalsCard
                    statsCard
                    cardsAndSubsCard
                    aiInsightCard
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Game Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let cached = MatchAIService.cachedText(forKey: insightCacheKey) {
                insightText = cached
            }
        }
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        VStack(spacing: 8) {
            Text(team.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GoStatsTheme.textMuted)

            Text("\(match.goalsFor) - \(match.goalsAgainst)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)

            Text(match.opponent.isEmpty ? "Opponent" : match.opponent)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GoStatsTheme.textMuted)

            HStack(spacing: 16) {
                if !match.venue.isEmpty {
                    Label(match.venue, systemImage: "mappin")
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.textMuted)
                }
                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.textMuted)
                Text(secondsToTime(match.secondsElapsed))
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
        )
    }

    // MARK: - Match Info

    private var matchInfoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                GoStatsTheme.sectionHeader("MATCH INFO")

                if !match.title.isEmpty {
                    Text(match.title)
                        .font(.custom("DM Sans", size: 15).weight(.medium))
                        .foregroundStyle(GoStatsTheme.text)
                }
                if !match.notes.isEmpty {
                    Text(match.notes)
                        .font(.custom("DM Sans", size: 13))
                        .foregroundStyle(GoStatsTheme.text2)
                }
                if match.title.isEmpty && match.notes.isEmpty {
                    Text("No additional info.")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundStyle(GoStatsTheme.emptyStateColor)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Goals

    private var goalsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                GoStatsTheme.sectionHeader("GOALS")

                let goalEvents = match.events.filter { $0.kind == .goal || $0.kind == .pkMade }
                if goalEvents.isEmpty {
                    emptyRow("No goals scored.")
                } else {
                    ForEach(goalEvents) { event in
                        HStack(spacing: 12) {
                            Text(secondsToTime(event.seconds))
                                .font(.custom("DM Mono", size: 13))
                                .foregroundStyle(GoStatsTheme.text2)
                                .frame(width: 50, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.custom("DM Sans", size: 14).weight(.medium))
                                    .foregroundStyle(GoStatsTheme.text)
                                if let detail = event.detail, !detail.isEmpty {
                                    Text(detail)
                                        .font(.custom("DM Sans", size: 12))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }
                            Spacer()
                            Text(event.kind == .pkMade ? "PK" : "")
                                .font(.custom("DM Sans", size: 11).weight(.medium))
                                .foregroundStyle(GoStatsTheme.text2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Aggregated Stats

    private var statsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                GoStatsTheme.sectionHeader("STATS")

                let totals = aggregateStats()
                statRow("Shots", "\(totals.shots)")
                statRow("Shots on Target", "\(totals.sot)")
                statRow("Saves", "\(totals.saves)")
                statRow("Goals Conceded", "\(match.goalsAgainst)")
            }
        }
    }

    // MARK: - Cards & Subs

    private var cardsAndSubsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                GoStatsTheme.sectionHeader("DISCIPLINE")

                let totals = aggregateStats()
                statRow("Yellow Cards", "\(totals.yellows)")
                statRow("Red Cards", "\(totals.reds)")

                let subEvents = match.events.filter { $0.title.lowercased().contains("sub") }
                statRow("Substitutions", "\(subEvents.count)")
            }
        }
    }

    // MARK: - AI Insight Card

    private var aiInsightCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.textMuted)
                    GoStatsTheme.sectionHeader("AI INSIGHT")
                }

                if let text = insightText {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "1a1a1a"))
                        .fixedSize(horizontal: false, vertical: true)

                    Button { regenerateInsight() } label: {
                        Text("Regenerate")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "aaaaaa"))
                    }
                    .buttonStyle(.plain)
                } else if insightLoading {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Analyzing match...")
                            .font(.system(size: 13))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else if let error = insightError {
                    VStack(spacing: 8) {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                        Button("Retry") { generateInsight() }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Button { generateInsight() } label: {
                        Text("Generate Insight")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: "1a1a1a"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func generateInsight() {
        insightLoading = true
        insightError = nil
        Task {
            do {
                let context = MatchAIService.buildMatchContext(match: match, team: team, players: team.players, includeTimingDetail: true)
                let systemPrompt = "You are a youth soccer performance analyst. Given this match data, provide one specific tactical insight that would help the coach improve. Focus on patterns like: when goals were scored, shot conversion rate, defensive vulnerabilities, or substitution timing. Be specific and actionable. 2-3 sentences max. Return only the insight text, nothing else."
                let text = try await MatchAIService.generate(systemPrompt: systemPrompt, userMessage: context)
                await MainActor.run {
                    insightText = text
                    insightLoading = false
                    MatchAIService.cacheText(text, forKey: insightCacheKey)
                }
            } catch {
                await MainActor.run {
                    insightError = "Couldn't generate insight. Check your connection and try again."
                    insightLoading = false
                }
            }
        }
    }

    private func regenerateInsight() {
        insightText = nil
        generateInsight()
    }

    // MARK: - Helpers

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.custom("DM Sans", size: 14))
                .foregroundStyle(GoStatsTheme.text)
            Spacer()
            Text(value)
                .font(.custom("DM Mono", size: 14))
                .foregroundStyle(GoStatsTheme.text2)
        }
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.custom("DM Sans", size: 13))
            .foregroundStyle(GoStatsTheme.emptyStateColor)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.vertical, 4)
    }

    private func secondsToTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }

    private struct AggregateStats {
        var shots = 0; var sot = 0; var saves = 0
        var yellows = 0; var reds = 0
    }

    private func aggregateStats() -> AggregateStats {
        var a = AggregateStats()
        for (_, line) in match.playerStats {
            a.shots += line.shots
            a.sot += line.shotsOnTarget
            a.saves += line.saves
            a.yellows += line.yellowCards
            a.reds += line.redCards
        }
        return a
    }
}
