import SwiftUI

/// Bottom sheet shown after saving a match — offers Save confirmation, Export Stats PDF, and Open in MaxPreps.
struct PostMatchExportSheet: View {
    let match: MatchRecord
    let team: Team
    let players: [Player]
    var onDone: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.maxPrepsTeamID) private var maxPrepsTeamID: String = ""

    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var summaryText: String? = nil
    @State private var summaryLoading = false
    @State private var summaryError: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Score header
                        VStack(spacing: 6) {
                            Text("\(team.name) vs \(match.opponent)")
                                .font(.custom("DM Sans", size: 17).weight(.medium))
                                .foregroundStyle(GoStatsTheme.text)

                            Text("\(match.goalsFor) - \(match.goalsAgainst)")
                                .font(.custom("DM Mono", size: 28))
                                .foregroundStyle(GoStatsTheme.text)

                            Text("Match saved!")
                                .font(.custom("DM Sans", size: 13))
                                .foregroundStyle(GoStatsTheme.positive)
                        }
                        .padding(.top, 8)

                        // AI Match Summary
                        VStack(alignment: .leading, spacing: 10) {
                            GoStatsTheme.sectionHeader("MATCH SUMMARY")

                            if let text = summaryText {
                                Text(text)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "1a1a1a"))
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: 12) {
                                    Button {
                                        UIPasteboard.general.string = text
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 12))
                                            Text("Copy")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        shareSheetPayload = ShareSheetPayload(items: [text])
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 12))
                                            Text("Share")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()
                                }
                            } else if summaryLoading {
                                HStack(spacing: 8) {
                                    ProgressView().controlSize(.small)
                                    Text("Generating summary...")
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            } else if let error = summaryError {
                                VStack(spacing: 8) {
                                    Text(error)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                    Button("Retry") { generateSummary() }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Button { generateSummary() } label: {
                                    Text("Generate Summary")
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
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor,
                                        radius: GoStatsTheme.cardShadowRadius,
                                        x: 0, y: GoStatsTheme.cardShadowY)
                        )

                        // Export Stats PDF
                        Button {
                            guard Paywall.require(.exports) else { return }
                            let url = GameStatsPDFGenerator.generatePDF(
                                teamName: team.name,
                                opponent: match.opponent,
                                date: match.date,
                                goalsFor: match.goalsFor,
                                goalsAgainst: match.goalsAgainst,
                                players: players,
                                stats: match.playerStats,
                                seconds: match.playerSeconds,
                                events: match.events
                            )
                            shareSheetPayload = ShareSheetPayload(items: [url])
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Export Stats PDF")
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                            }
                            .font(.custom("DM Sans", size: 16).weight(.medium))
                            .foregroundStyle(GoStatsTheme.text)
                            .padding(14)
                            .modifier(CardModifier())
                        }
                        .buttonStyle(.plain)

                        // Export MaxPreps TXT
                        Button {
                            exportMaxPrepsTXT()
                        } label: {
                            HStack {
                                Image(systemName: "tablecells")
                                Text("Export MaxPreps (.txt)")
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                            }
                            .font(.custom("DM Sans", size: 16).weight(.medium))
                            .foregroundStyle(GoStatsTheme.text)
                            .padding(14)
                            .modifier(CardModifier())
                        }
                        .buttonStyle(.plain)

                        // Open in MaxPreps (only if Team ID is set)
                        if !maxPrepsTeamID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                openMaxPreps()
                            } label: {
                                HStack {
                                    Image(systemName: "link")
                                    Text("Open in MaxPreps")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.custom("DM Sans", size: 16).weight(.medium))
                                .foregroundStyle(GoStatsTheme.positive)
                                .padding(14)
                                .modifier(CardModifier())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }

                // Done button pinned at bottom
                Button {
                    dismiss()
                    onDone?()
                } label: {
                    Text("Done")
                        .font(.custom("DM Sans", size: 16).weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rButton, style: .continuous)
                                .fill(GoStatsTheme.scoreBg)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Match Saved")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .sheet(item: $shareSheetPayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .onAppear {
            if let cached = MatchAIService.cachedText(forKey: "match_summary_\(match.id.uuidString)") {
                summaryText = cached
            }
        }
    }

    // MARK: - AI Summary

    private func generateSummary() {
        guard Paywall.require(.aiRecaps) else { return }
        summaryLoading = true
        summaryError = nil
        Task {
            do {
                let context = MatchAIService.buildMatchContext(match: match, team: team, players: players)
                let systemPrompt = "You are a youth soccer match analyst. Given the following match data, write a 2-3 sentence match summary that a coach could share with parents. Be specific about scorers, saves, and standout moments. Keep it positive and factual. Return only the summary text, nothing else."
                let text = try await MatchAIService.generate(systemPrompt: systemPrompt, userMessage: context)
                await MainActor.run {
                    summaryText = text
                    summaryLoading = false
                    MatchAIService.cacheText(text, forKey: "match_summary_\(match.id.uuidString)")
                }
            } catch let error as MatchAIService.AIError {
                await MainActor.run {
                    summaryError = error.errorDescription
                    summaryLoading = false
                }
            } catch {
                await MainActor.run {
                    summaryError = "Couldn't generate summary. Check your connection and try again."
                    summaryLoading = false
                }
            }
        }
    }

    // MARK: - MaxPreps TXT

    private func exportMaxPrepsTXT() {
        guard Paywall.require(.exports) else { return }
        let teamRows = MaxPrepsExport.teamRows(
            players: players,
            stats: match.playerStats,
            seconds: match.playerSeconds
        )
        let teamText = MaxPrepsExport.text(fields: MaxPrepsExport.teamFields, rows: teamRows)

        var urls: [URL] = []
        if let teamURL = try? MaxPrepsExport.writeTempTXT(
            filename: "MaxPreps_\(MaxPrepsExport.sanitizedFilename(match.opponent))_Team",
            contents: teamText
        ) {
            urls.append(teamURL)
        }

        let keeperRows = MaxPrepsExport.keeperRows(
            players: players,
            stats: match.playerStats,
            seconds: match.playerSeconds
        )
        if !keeperRows.isEmpty {
            let keeperText = MaxPrepsExport.text(fields: MaxPrepsExport.keeperFields, rows: keeperRows)
            if let keeperURL = try? MaxPrepsExport.writeTempTXT(
                filename: "MaxPreps_\(MaxPrepsExport.sanitizedFilename(match.opponent))_Keeper",
                contents: keeperText
            ) {
                urls.append(keeperURL)
            }
        }

        if !urls.isEmpty {
            shareSheetPayload = ShareSheetPayload(items: urls)
        }
    }

    // MARK: - Deep Link

    private func openMaxPreps() {
        let trimmed = maxPrepsTeamID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let urlString = "https://www.maxpreps.com/local/team/records/default.aspx?teamid=\(trimmed)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }
}
