import SwiftUI

struct MatchView: View {

    @ObservedObject var store: MatchStore
    var teamStore: TeamStore
    let teamID: UUID

    @State private var showingEndSheet = false
    @State private var showHaptics = true

    // ✅ FIX: EndMatchSheet needs Formation (not Formation?)
    // Uses the store’s formation if set, otherwise falls back to the first available formation.
    private var resolvedFormation: Formation {
        store.formation ?? Formation.allCases.first!
    }

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    scoreCard
                    fieldCard
                    controlRow
                    quickEventsTeam
                    quickEventsKeeper

                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { showingEndSheet = true }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showingEndSheet) {
            // ✅ FIX: EndMatchSheet now requires team + formation
            if let team = teamStore.teams.first(where: { $0.id == teamID }) {
                EndMatchSheet(
                    store: store,
                    teamStore: teamStore,
                    teamID: teamID,
                    team: team,
                    formation: resolvedFormation
                )
            } else {
                NavigationStack {
                    VStack(spacing: 12) {
                        Text("Team not found")
                            .font(.headline)
                        Text("Go back and pick a team again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .navigationTitle("End Match")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onAppear { store.loadSampleIfEmpty() }
    }

    // MARK: - Cards

    private var scoreCard: some View {
        LiquidGlassContainer(material: .thinMaterial) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.timeString)
                        .font(.system(size: 26, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text)

                    Text("TIME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                Spacer()

                Text("\(store.goalsFor)–\(store.goalsAgainst)")
                    .font(.system(size: 30, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GoStatsTheme.text)
            }
        }
    }

    private var fieldCard: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("FIELD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                FieldView1443(store: store)
            }
        }
    }

    private var controlRow: some View {
        LiquidGlassContainer {
            HStack {
                Button {
                    haptic(.medium)
                    store.pushUndo()
                    store.undoLast()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(GlassPillButtonStyle(fill: Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65)))

                Spacer()

                Button {
                    haptic(.light)
                    // Placeholder sub action
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sub")
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary.opacity(0.95)))
            }
        }
    }

    // MARK: - Quick Events

    private var quickEventsTeam: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK EVENTS — TEAM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickButton("Goal") {
                        store.pushUndo()
                        store.goalsFor += 1
                    }
                    quickButton("Shot") {
                        store.pushUndo()
                        // wire to stats later
                    }
                    quickButton("Own Goal") {
                        store.pushUndo()
                        store.goalsAgainst += 1
                    }
                    quickButton("PK Attempt") {
                        store.pushUndo()
                    }
                    quickButton("Card") {
                        store.pushUndo()
                    }
                    quickButton("PK Made") {
                        store.pushUndo()
                        store.goalsFor += 1
                    }
                }
            }
        }
    }

    private var quickEventsKeeper: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK EVENTS — KEEPER")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickButton("Save") {
                        store.pushUndo()
                    }
                    quickButton("Conceded") {
                        store.pushUndo()
                        store.goalsAgainst += 1
                    }
                    quickButton("PK Saved") {
                        store.pushUndo()
                    }
                    quickButton("PK Conceded") {
                        store.pushUndo()
                        store.goalsAgainst += 1
                    }
                }
            }
        }
    }

    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            haptic(.light)
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassPillButtonStyle(fill: GoStatsTheme.primary.opacity(0.95)))
    }

    // MARK: - Data

    private var onFieldPlayers: [Player] {
        let set = store.onFieldIDs
        return store.players.filter { set.contains($0.id) }
    }

    // MARK: - Haptics

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard showHaptics else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

