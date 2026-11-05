import SwiftUI

/// Pick halves or quarters and the period length before kickoff.
/// Saved to the team by default so the next match starts the same way.
struct MatchFormatSheet: View {
    @ObservedObject var store: MatchStore
    let teamStore: TeamStore
    let teamID: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var periodCount: Int
    @State private var periodMinutes: Int
    @State private var saveForTeam = true

    /// Common youth formats, shown as one-tap presets.
    private let presets: [(label: String, count: Int, minutes: Int)] = [
        ("U8 · 4 × 10", 4, 10),
        ("U10 · 2 × 25", 2, 25),
        ("U12 · 2 × 30", 2, 30),
        ("U14 · 2 × 35", 2, 35),
        ("HS · 2 × 40", 2, 40),
        ("Adult · 2 × 45", 2, 45),
    ]

    init(store: MatchStore, teamStore: TeamStore, teamID: UUID) {
        self.store = store
        self.teamStore = teamStore
        self.teamID = teamID
        _periodCount = State(initialValue: store.periodCount)
        _periodMinutes = State(initialValue: store.periodMinutes)
    }

    private var teamName: String {
        teamStore.teams.first(where: { $0.id == teamID })?.name ?? "this team"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Periods", selection: $periodCount) {
                        Text("Halves").tag(2)
                        Text("Quarters").tag(4)
                    }
                    .pickerStyle(.segmented)

                    Stepper(value: $periodMinutes, in: 0...60) {
                        HStack {
                            Text(periodCount == 4 ? "Quarter length" : "Half length")
                            Spacer()
                            Text(periodMinutes == 0 ? "No set length" : "\(periodMinutes) min")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                } footer: {
                    Text(periodMinutes == 0
                         ? "The clock counts up with no countdown."
                         : "The header shows time left in each \(periodCount == 4 ? "quarter" : "half"). When it runs out your phone buzzes; the clock keeps going for stoppage time until you end the period.")
                }

                Section("Presets") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(presets, id: \.label) { preset in
                            let isOn = preset.count == periodCount && preset.minutes == periodMinutes
                            Button {
                                Haptics.light()
                                periodCount = preset.count
                                periodMinutes = preset.minutes
                            } label: {
                                Text(preset.label)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(isOn ? .white : GoStatsTheme.textPrimary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isOn ? GoStatsTheme.textPrimary : GoStatsTheme.surface)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Use for every \(teamName) match", isOn: $saveForTeam)
                }
            }
            .navigationTitle("Match Format")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { apply() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func apply() {
        store.periodCount = periodCount
        store.periodMinutes = periodMinutes
        if saveForTeam, var team = teamStore.teams.first(where: { $0.id == teamID }) {
            team.periodCount = periodCount
            team.periodMinutes = periodMinutes
            teamStore.updateTeam(team)
        }
        store.persist()
        dismiss()
    }
}
