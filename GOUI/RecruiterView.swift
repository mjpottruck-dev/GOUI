import SwiftUI
import UIKit

struct RecruiterView: View {
    @Bindable var teamStore: TeamStore

    @State private var filter = RecruiterFilterState()
    @State private var savedPlayerIDs: Set<UUID> = []
    @State private var showContactAlert = false
    @State private var gradYearText: String = ""

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    filterCard

                    ForEach(filteredPlayers) { entry in
                        playerCard(entry.player, sport: entry.sport)
                    }

                    if filteredPlayers.isEmpty {
                        LiquidGlassContainer(cornerRadius: 22) {
                            Text("No recruiting matches yet.")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Recruiter Mode")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Contact Coach", isPresented: $showContactAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coach contact will be available in the next release. For now, share the public profile link.")
        }
    }

    private var filterCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SEARCH FILTERS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                Picker("Sport", selection: $filter.sportID) {
                    Text("All Sports").tag(String?.none)
                    ForEach(SportCatalog.all, id: \.id) { sport in
                        Text(sport.displayName).tag(Optional(sport.id))
                    }
                }
                .pickerStyle(.menu)

                TextField("Grad Year", text: $gradYearText)
                    .keyboardType(.numberPad)
                    .onChange(of: gradYearText) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        filter.gradYear = Int(trimmed)
                    }

                TextField("Region", text: $filter.region)

                HStack {
                    Text("Min Primary Stat")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                    Spacer()
                    Stepper(value: $filter.minPrimaryStat, in: 0...50) {
                        Text("\(filter.minPrimaryStat)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(GoStatsTheme.text)
                    }
                }
            }
        }
    }

    private var filteredPlayers: [RecruitingPlayerEntry] {
        let all = teamStore.teams.flatMap { team -> [RecruitingPlayerEntry] in
            let sport = SportCatalog.sport(for: team.sportID)
            return team.players.map { player in
                RecruitingPlayerEntry(player: player, sport: sport)
            }
        }

        return all.filter { entry in
            if let sportID = filter.sportID, entry.sport.id != sportID {
                return false
            }
            if let gradYear = filter.gradYear, entry.player.profile.gradYear != gradYear {
                return false
            }
            if !filter.region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let region = filter.region.lowercased()
                if !entry.player.profile.region.lowercased().contains(region) {
                    return false
                }
            }
            if filter.minPrimaryStat > 0 {
                let statID = entry.sport.scoringRules.primaryStatID
                let statValue = entry.player.statValue(for: statID)
                if statValue < filter.minPrimaryStat {
                    return false
                }
            }
            return true
        }
    }

    private func playerCard(_ player: Player, sport: any SportDefinition) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("#\(player.number) \(player.name)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("\(sport.displayName) • \(player.profile.region.isEmpty ? "Region TBD" : player.profile.region)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    Spacer()
                    Button {
                        toggleSaved(player)
                    } label: {
                        Image(systemName: savedPlayerIDs.contains(player.id) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(GoStatsTheme.primary)
                    }
                }

                HStack(spacing: 12) {
                    infoPill(label: "Grad", value: player.profile.gradYear.map(String.init) ?? "TBD")
                    infoPill(label: "GPA", value: player.profile.gpa.map { String(format: "%.2f", $0) } ?? "-")
                    infoPill(label: sport.scoringRules.scoreLabel, value: "\(player.statValue(for: sport.scoringRules.primaryStatID))")
                }

                HStack {
                    Button("Public Profile") {
                        if player.profile.publicProfileURL != nil {
                            UIPasteboard.general.string = player.profile.publicProfileURL?.absoluteString
                        }
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary))
                    .disabled(player.profile.publicProfileURL == nil)

                    Button("Contact Coach") {
                        showContactAlert = true
                    }
                    .buttonStyle(GlassPillButtonStyle(fill: Color.white.opacity(0.15)))
                }
            }
        }
    }

    private func infoPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
        )
    }

    private func toggleSaved(_ player: Player) {
        if savedPlayerIDs.contains(player.id) {
            savedPlayerIDs.remove(player.id)
        } else {
            savedPlayerIDs.insert(player.id)
        }
    }
}

private struct RecruitingPlayerEntry: Identifiable {
    let player: Player
    let sport: any SportDefinition

    var id: UUID { player.id }
}
