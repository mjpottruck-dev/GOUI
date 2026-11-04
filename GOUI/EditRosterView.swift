import SwiftUI

struct EditRosterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var teamName: String
    @State private var fieldSize: Int
    @State private var players: [Player]
    @State private var startingOnFieldIDs: Set<UUID>
    @State private var primaryFormation: Formation
    @State private var primaryGoalkeeperID: UUID?
    @State private var secondaryGoalkeeperID: UUID?
    @State private var thirdGoalkeeperID: UUID?
    @State private var createdAt: Date
    @State private var matches: [MatchRecord]

    let onSave: (Team) -> Void
    let existingTeamID: UUID

    init(team: Team, onSave: @escaping (Team) -> Void) {
        self._teamName = State(initialValue: team.name)
        self._fieldSize = State(initialValue: team.fieldSize)
        self._players = State(initialValue: team.players)
        self._startingOnFieldIDs = State(initialValue: Set(team.startingOnFieldIDs))
        self._primaryFormation = State(initialValue: team.primaryFormation)
        self._primaryGoalkeeperID = State(initialValue: team.primaryGoalkeeperID)
        self._secondaryGoalkeeperID = State(initialValue: team.secondaryGoalkeeperID)
        self._thirdGoalkeeperID = State(initialValue: team.thirdGoalkeeperID)
        self._createdAt = State(initialValue: team.createdAt)
        self._matches = State(initialValue: team.matches)
        self.onSave = onSave
        self.existingTeamID = team.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f5f5").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GoStatsTheme.cardGap) {

                        // Team Info card
                        VStack(alignment: .leading, spacing: 12) {
                            GoStatsTheme.sectionHeader("TEAM")

                            TextField("Team name", text: $teamName)
                                .font(.system(size: 15))
                                .foregroundStyle(GoStatsTheme.textPrimary)

                            Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Field Size")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                                Picker("Field Size", selection: $fieldSize) {
                                    Text("7v7").tag(7)
                                    Text("9v9").tag(9)
                                    Text("11v11").tag(11)
                                }
                                .pickerStyle(.segmented)
                            }

                            Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                            Picker("Primary Formation", selection: $primaryFormation) {
                                ForEach(Formation.allCases.filter { $0.playerCount == fieldSize }) { formation in
                                    Text(formation.rawValue).tag(formation)
                                }
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                        )

                        // Starting On Field card
                        VStack(alignment: .leading, spacing: 12) {
                            GoStatsTheme.sectionHeader("STARTING ON FIELD")

                            Text("Tap players to toggle on/off the field.")
                                .font(.system(size: 13))
                                .foregroundStyle(GoStatsTheme.textMuted)

                            ForEach(Array(players.enumerated()), id: \.element.id) { index, p in
                                if index > 0 {
                                    Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)
                                }
                                Button { toggleStarter(p.id) } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(GoStatsTheme.textPrimary)
                                                .frame(width: 32, height: 32)
                                            Text("\(p.number)")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        Text(p.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(GoStatsTheme.textPrimary)
                                        Spacer()
                                        Text(p.position.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundStyle(GoStatsTheme.textMuted)
                                        Image(systemName: startingOnFieldIDs.contains(p.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(startingOnFieldIDs.contains(p.id) ? GoStatsTheme.positive : GoStatsTheme.textMuted)
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                            Text("Selected: \(startingOnFieldIDs.count) / \(fieldSize)")
                                .font(.system(size: 13))
                                .foregroundStyle(starterCountColor)
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                        )

                        // Goalkeepers card
                        VStack(alignment: .leading, spacing: 12) {
                            GoStatsTheme.sectionHeader("GOALKEEPERS")

                            if goalkeeperOptions.isEmpty {
                                Text("Add goalkeepers to assign depth.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            } else {
                                Picker("Primary", selection: $primaryGoalkeeperID) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(goalkeeperOptions) { player in
                                        Text(goalkeeperLabel(for: player)).tag(Optional(player.id))
                                    }
                                }

                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                Picker("Secondary", selection: $secondaryGoalkeeperID) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(goalkeeperOptions) { player in
                                        Text(goalkeeperLabel(for: player)).tag(Optional(player.id))
                                    }
                                }

                                Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                                Picker("Third", selection: $thirdGoalkeeperID) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(goalkeeperOptions) { player in
                                        Text(goalkeeperLabel(for: player)).tag(Optional(player.id))
                                    }
                                }
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
                        )
                    }
                    .padding(.horizontal, GoStatsTheme.cardMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Roster")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: fieldSize) { _, newSize in
                if primaryFormation.playerCount != newSize {
                    primaryFormation = Formation.defaultFormation(for: newSize)
                }
                if startingOnFieldIDs.count != newSize {
                    startingOnFieldIDs = Set(players.prefix(newSize).map(\.id))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let clamped = players.filter { startingOnFieldIDs.contains($0.id) }.prefix(fieldSize).map(\.id)
                        let resolvedDepth = Team.goalkeeperDepthIDs(
                            from: players,
                            currentPrimary: primaryGoalkeeperID,
                            currentSecondary: secondaryGoalkeeperID,
                            currentThird: thirdGoalkeeperID
                        )
                        let team = Team(
                            id: existingTeamID,
                            name: teamName.trimmingCharacters(in: .whitespacesAndNewlines),
                            players: players,
                            createdAt: createdAt,
                            updatedAt: Date(),
                            fieldSize: fieldSize,
                            startingOnFieldIDs: clamped,
                            primaryFormation: primaryFormation,
                            primaryGoalkeeperID: resolvedDepth.primary,
                            secondaryGoalkeeperID: resolvedDepth.secondary,
                            thirdGoalkeeperID: resolvedDepth.third,
                            matches: matches
                        )
                        onSave(team)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var starterCountColor: Color {
        startingOnFieldIDs.count == fieldSize ? GoStatsTheme.textMuted : .red
    }

    private func toggleStarter(_ id: UUID) {
        if startingOnFieldIDs.contains(id) {
            startingOnFieldIDs.remove(id)
        } else {
            if startingOnFieldIDs.count < fieldSize {
                startingOnFieldIDs.insert(id)
            }
        }
    }

    private var goalkeeperOptions: [Player] {
        players.filter { $0.position == .gk }.sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.number < rhs.number
        }
    }

    private func goalkeeperLabel(for player: Player) -> String {
        "#\(player.number) \(player.name)"
    }
}
