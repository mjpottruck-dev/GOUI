import Foundation

/// Handles smart position assignment for line changes.
/// Given incoming players and open formation slots, assigns each player
/// to the best available position using a priority system.
struct SmartPositionAssigner {

    struct Assignment {
        let player: Player
        let slotIndex: Int
        let assignedPosition: Position
        let reason: AssignmentReason
    }

    enum AssignmentReason {
        case primaryPosition
        case secondaryPosition
        case bestFit(primaryPosition: Position)
        case correctionMemory
        case fallback

        var label: String {
            switch self {
            case .primaryPosition: return "primary position"
            case .secondaryPosition: return "secondary position"
            case .bestFit: return "best fit"
            case .correctionMemory: return "based on previous correction"
            case .fallback: return "no ideal fit"
            }
        }

        var needsWarning: Bool {
            switch self {
            case .bestFit, .fallback: return true
            default: return false
            }
        }
    }

    /// Positional family mapping for Priority 3 — which positions can fill which slots
    private static let positionalFamilies: [Position: [Position]] = [
        .st:  [.cam, .rw, .lw, .cf],
        .cf:  [.cam, .st, .rw, .lw],
        .cam: [.cm, .st, .am],
        .am:  [.cam, .cm],
        .cm:  [.cdm, .cam, .am],
        .cdm: [.cb, .cm, .dm],
        .dm:  [.cdm, .cm, .cb],
        .cb:  [.rb, .lb, .cdm],
        .rb:  [.cb, .rm, .rwb],
        .lb:  [.cb, .lm, .lwb],
        .rwb: [.rb, .rm],
        .lwb: [.lb, .lm],
        .rm:  [.rb, .rw, .rwb],
        .lm:  [.lb, .lw, .lwb],
        .rw:  [.rm, .st, .cf],
        .lw:  [.lm, .st, .cf],
        .gk:  [.gk],
    ]

    /// Assign incoming players to open formation slots.
    /// - Parameters:
    ///   - incomingPlayers: Players coming onto the field
    ///   - openSlots: Array of (slotIndex, position) pairs that are now open
    ///   - correctionRules: Previously stored coach corrections
    /// - Returns: Array of assignments
    static func assign(
        incomingPlayers: [Player],
        openSlots: [(index: Int, position: Position)],
        correctionRules: [CorrectionRule] = []
    ) -> [Assignment] {
        var remaining = incomingPlayers
        var availableSlots = openSlots
        var assignments: [Assignment] = []

        // Priority 0: Check correction memory
        for rule in correctionRules {
            for (playerID, correctedPos) in rule.correctedPositions {
                guard let playerIdx = remaining.firstIndex(where: { $0.id == playerID }),
                      let slotIdx = availableSlots.firstIndex(where: { $0.position == correctedPos })
                else { continue }

                let player = remaining[playerIdx]
                let slot = availableSlots[slotIdx]
                assignments.append(Assignment(
                    player: player,
                    slotIndex: slot.index,
                    assignedPosition: slot.position,
                    reason: .correctionMemory
                ))
                remaining.remove(at: playerIdx)
                availableSlots.remove(at: slotIdx)
            }
        }

        // Priority 1: Primary position exact match
        for i in stride(from: remaining.count - 1, through: 0, by: -1) {
            let player = remaining[i]
            if let slotIdx = availableSlots.firstIndex(where: { $0.position == player.position }) {
                let slot = availableSlots[slotIdx]
                assignments.append(Assignment(
                    player: player,
                    slotIndex: slot.index,
                    assignedPosition: slot.position,
                    reason: .primaryPosition
                ))
                remaining.remove(at: i)
                availableSlots.remove(at: slotIdx)
            }
        }

        // Priority 2: Secondary position match
        for i in stride(from: remaining.count - 1, through: 0, by: -1) {
            let player = remaining[i]
            if let secondary = player.secondaryPosition,
               let slotIdx = availableSlots.firstIndex(where: { $0.position == secondary }) {
                let slot = availableSlots[slotIdx]
                assignments.append(Assignment(
                    player: player,
                    slotIndex: slot.index,
                    assignedPosition: slot.position,
                    reason: .secondaryPosition
                ))
                remaining.remove(at: i)
                availableSlots.remove(at: slotIdx)
            }
        }

        // Priority 3: Positional family best fit
        for i in stride(from: remaining.count - 1, through: 0, by: -1) {
            let player = remaining[i]
            let family = positionalFamilies[player.position] ?? []
            if let slotIdx = availableSlots.firstIndex(where: { family.contains($0.position) }) {
                let slot = availableSlots[slotIdx]
                assignments.append(Assignment(
                    player: player,
                    slotIndex: slot.index,
                    assignedPosition: slot.position,
                    reason: .bestFit(primaryPosition: player.position)
                ))
                remaining.remove(at: i)
                availableSlots.remove(at: slotIdx)
            }
        }

        // Priority 4: Fallback — assign to any remaining slot
        for i in stride(from: remaining.count - 1, through: 0, by: -1) {
            guard !availableSlots.isEmpty else { break }
            let player = remaining[i]
            let slot = availableSlots.removeFirst()
            assignments.append(Assignment(
                player: player,
                slotIndex: slot.index,
                assignedPosition: slot.position,
                reason: .fallback
            ))
            remaining.remove(at: i)
        }

        return assignments
    }
}
