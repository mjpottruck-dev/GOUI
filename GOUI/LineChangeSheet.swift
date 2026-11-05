import SwiftUI

struct LineChangeSheet: View {
    @ObservedObject var store: MatchStore
    @Environment(\.dismiss) private var dismiss

    @State private var playersGoingOff: Set<UUID> = []
    @State private var playersComingOn: Set<UUID> = []
    @State private var showPreview = false
    @State private var assignments: [SmartPositionAssigner.Assignment] = []

    private var onField: [Player] { store.onFieldPlayers }
    private var bench: [Player] {
        let ids = Set(onField.map { $0.id })
        return store.players.filter { !ids.contains($0.id) }
    }

    private var canProceed: Bool {
        !playersGoingOff.isEmpty && playersGoingOff.count == playersComingOn.count
    }

    var body: some View {
        NavigationStack {
            if showPreview {
                previewScreen
            } else {
                selectionScreen
            }
        }
    }

    // MARK: - Selection Screen

    private var selectionScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Tap field players to mark OFF, bench players to mark ON. Select equal numbers.")
                    .font(.custom("DM Sans", size: 13))
                    .foregroundStyle(GoStatsTheme.textMuted)
                    .padding(.horizontal)

                // On Field
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("On Field").font(.headline)
                        Spacer()
                        if !playersGoingOff.isEmpty {
                            Text("\(playersGoingOff.count) coming off")
                                .font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(onField) { player in
                            let isMarked = playersGoingOff.contains(player.id)
                            Button {
                                if isMarked { playersGoingOff.remove(player.id) }
                                else { playersGoingOff.insert(player.id) }
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(player.number)")
                                        .font(.custom("DM Mono", size: 14))
                                    Text(player.name.split(separator: " ").first.map(String.init) ?? player.name)
                                        .font(.custom("DM Sans", size: 10))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                        .fill(isMarked ? Color.red.opacity(0.12) : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                        .stroke(isMarked ? Color.red.opacity(0.5) : GoStatsTheme.cardBorder, lineWidth: isMarked ? 1.5 : GoStatsTheme.cardBorderWidth)
                                )
                                .foregroundStyle(GoStatsTheme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // Bench
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Bench").font(.headline)
                        Spacer()
                        if !playersComingOn.isEmpty {
                            Text("\(playersComingOn.count) coming on")
                                .font(.caption).foregroundStyle(GoStatsTheme.positive)
                        }
                    }
                    .padding(.horizontal)

                    if bench.isEmpty {
                        Text("No bench players available.")
                            .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(bench) { player in
                                let isMarked = playersComingOn.contains(player.id)
                                Button {
                                    if isMarked { playersComingOn.remove(player.id) }
                                    else { playersComingOn.insert(player.id) }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(player.number)")
                                            .font(.custom("DM Mono", size: 14))
                                        Text(player.name.split(separator: " ").first.map(String.init) ?? player.name)
                                            .font(.custom("DM Sans", size: 10))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                            .fill(isMarked ? GoStatsTheme.positive.opacity(0.12) : Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                            .stroke(isMarked ? GoStatsTheme.positive.opacity(0.5) : GoStatsTheme.cardBorder, lineWidth: isMarked ? 1.5 : GoStatsTheme.cardBorderWidth)
                                    )
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Line Change")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") { buildPreview() }
                    .disabled(!canProceed)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }

    // MARK: - Preview Screen

    private var previewScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Review each assignment before confirming.")
                        .font(.custom("DM Sans", size: 13))
                        .foregroundStyle(GoStatsTheme.textMuted)
                        .padding(.horizontal)

                    ForEach(assignments, id: \.player.id) { assignment in
                        HStack(spacing: 10) {
                            Text(store.displayName(for: assignment.player))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.textPrimary)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.textMuted)

                            Text(assignment.assignedPosition.rawValue)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(GoStatsTheme.textPrimary)

                            Spacer()

                            if assignment.reason.needsWarning {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "F59E0B"))
                            }

                            Text(assignment.reason.label)
                                .font(.system(size: 11))
                                .foregroundStyle(GoStatsTheme.textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .stroke(
                                    assignment.reason.needsWarning ? Color(hex: "F59E0B").opacity(0.4) : GoStatsTheme.cardBorder,
                                    lineWidth: GoStatsTheme.cardBorderWidth
                                )
                        )
                        .padding(.horizontal)
                    }

                    if assignments.contains(where: { $0.reason.needsWarning }) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "F59E0B"))
                            Text("Best fit \u{2014} verify position")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "F59E0B"))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }

            VStack(spacing: 10) {
                Button { confirmLineChange() } label: {
                    Text("Confirm Line Change")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .fill(Color(hex: "1a1a1a"))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    showPreview = false
                } label: {
                    Text("Adjust Manually")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(GoStatsTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .stroke(Color(hex: "cccccc"), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .navigationTitle("Line Change Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { showPreview = false }
            }
        }
    }

    // MARK: - Build Preview

    private func buildPreview() {
        let formation = store.formation ?? .f433
        let slots = formation.slotPositions

        let incomingPlayers = playersComingOn.compactMap { id in
            store.players.first(where: { $0.id == id })
        }

        // Determine which slots are opening up
        var openSlots: [(index: Int, position: Position)] = []
        for offID in playersGoingOff {
            if let idx = store.onFieldLineupIDs.firstIndex(of: offID), idx < slots.count {
                openSlots.append((index: idx, position: slots[idx]))
            }
        }

        // Check for correction rules
        let incomingIDs = Set(playersComingOn)
        let correctionRules = CorrectionMemoryStore.shared.matchingRules(for: incomingIDs)

        assignments = SmartPositionAssigner.assign(
            incomingPlayers: incomingPlayers,
            openSlots: openSlots,
            correctionRules: correctionRules
        )

        showPreview = true
    }

    // MARK: - Confirm

    private func confirmLineChange() {
        store.refreshElapsedFromClock()
        store.pushUndo()

        let offArray = Array(playersGoingOff)

        // Apply smart assignments
        for assignment in assignments {
            let onID = assignment.player.id
            if assignment.slotIndex < store.onFieldLineupIDs.count {
                store.onFieldLineupIDs[assignment.slotIndex] = onID
            }
            store.onFieldIDs.insert(onID)
        }

        // Remove outgoing players from field
        for offID in offArray {
            store.onFieldIDs.remove(offID)
        }

        // Handle goalkeeper promotion
        for assignment in assignments {
            if assignment.player.position == .gk,
               assignment.assignedPosition == .gk {
                store.promoteGoalkeeper(assignment.player.id)
            }
        }

        store.markPlayerSecondsBaseline()

        // Log event
        let offNames = offArray.compactMap { id in store.players.first(where: { $0.id == id }) }
            .map { store.displayName(for: $0) }.joined(separator: ", ")
        let onNames = assignments.map { store.displayName(for: $0.player) }.joined(separator: ", ")

        let detail = "OFF: \(offNames) | ON: \(onNames)"
        let event = MatchEvent(kind: .substitution, seconds: store.secondsElapsed, title: "Line Change (\(offArray.count) subs)", detail: detail)
        store.events.insert(event, at: 0)
        store.persist()

        // Store the assignment for correction tracking
        LineChangeTracker.shared.recordLineChange(
            assignments: assignments,
            matchMinute: store.secondsElapsed / 60,
            goalsFor: store.goalsFor,
            goalsAgainst: store.goalsAgainst,
            hasSplitHalf: store.hasSplitHalf
        )

        dismiss()
    }
}

/// Tracks line changes and detects coach corrections within 2 minutes.
final class LineChangeTracker: ObservableObject {
    static let shared = LineChangeTracker()

    struct PendingLineChange {
        let assignments: [SmartPositionAssigner.Assignment]
        let timestamp: Date
        let matchMinute: Int
        let goalsFor: Int
        let goalsAgainst: Int
        let half: Int
    }

    @Published var pendingChange: PendingLineChange? = nil

    func recordLineChange(assignments: [SmartPositionAssigner.Assignment], matchMinute: Int, goalsFor: Int, goalsAgainst: Int, hasSplitHalf: Bool) {
        pendingChange = PendingLineChange(
            assignments: assignments,
            timestamp: Date(),
            matchMinute: matchMinute,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst,
            half: hasSplitHalf ? 2 : 1
        )
    }

    /// Called when the coach manually moves a player on the field diagram.
    /// If within 2 minutes of a line change, treat as a correction.
    func checkForCorrection(movedPlayerID: UUID, fromSlotIndex: Int, toSlotIndex: Int, formation: Formation) {
        guard let pending = pendingChange,
              Date().timeIntervalSince(pending.timestamp) <= 120 else { return }

        let slots = formation.slotPositions
        guard fromSlotIndex < slots.count, toSlotIndex < slots.count else { return }

        // Build corrected positions from the assignments
        var correctedPositions: [UUID: Position] = [:]
        var originalPositions: [String: String] = [:]
        var playerIDs: [UUID] = []

        for assignment in pending.assignments {
            playerIDs.append(assignment.player.id)
            originalPositions[assignment.player.id.uuidString] = assignment.assignedPosition.rawValue
            correctedPositions[assignment.player.id] = assignment.assignedPosition
        }

        // Apply the manual correction
        if pending.assignments.contains(where: { $0.player.id == movedPlayerID }) {
            correctedPositions[movedPlayerID] = slots[toSlotIndex]
        }

        let rule = CorrectionRule(
            playerIDs: playerIDs,
            originalPositions: originalPositions,
            correctedPositions: correctedPositions,
            matchMinute: pending.matchMinute,
            scoreDiff: pending.goalsFor - pending.goalsAgainst,
            half: pending.half
        )

        CorrectionMemoryStore.shared.addRule(rule)
        pendingChange = nil
    }
}
