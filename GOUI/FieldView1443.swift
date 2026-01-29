import SwiftUI

struct FieldView1443: View {
    @ObservedObject var store: MatchStore
    var selectedPlayerID: Player.ID? = nil
    var onSelectPlayer: ((Player) -> Void)? = nil

    var body: some View {
        let onFieldPlayers = store.onFieldPlayers
        let formation = store.formation ?? .f433

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let inset: CGFloat = 14
            let fieldSize = CGSize(width: w - (inset * 2), height: h - (inset * 2))

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                    .padding(inset)

                fieldLines(size: fieldSize)
                    .frame(width: fieldSize.width, height: fieldSize.height)
                    .position(x: w * 0.5, y: h * 0.5)

                playersOverlay(players: onFieldPlayers, formation: formation, size: fieldSize)
                    .frame(width: fieldSize.width, height: fieldSize.height)
                    .position(x: w * 0.5, y: h * 0.5)
            }
        }
        .frame(height: 390)
        .accessibilityLabel("Field view")
    }

    // MARK: - Field Lines
    private func fieldLines(size: CGSize) -> some View {
        let w = size.width
        let h = size.height

        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)

            Path { p in
                p.move(to: CGPoint(x: w * 0.10, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.90, y: h * 0.50))
            }
            .stroke(Color.primary.opacity(0.10), lineWidth: 1)

            Circle()
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                .frame(width: min(w, h) * 0.22, height: min(w, h) * 0.22)
                .position(x: w * 0.50, y: h * 0.50)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                .frame(width: w * 0.42, height: h * 0.18)
                .position(x: w * 0.50, y: h * 0.82)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                .frame(width: w * 0.42, height: h * 0.18)
                .position(x: w * 0.50, y: h * 0.18)
        }
    }

    // MARK: - Players Overlay
    private func playersOverlay(players: [Player], formation: Formation, size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        let slots = formation.lineLayout

        let gk = store.activeGoalkeeper()
        let fieldPlayers = players.filter { $0.id != gk?.id }

        let lineCount = slots.count
        let startY: CGFloat = 0.70
        let endY: CGFloat = 0.20
        let step = lineCount > 1 ? (startY - endY) / CGFloat(lineCount - 1) : 0

        var assigned: [(Player, Position, CGPoint)] = []
        var openSlots: [(Position, CGPoint)] = []
        for (lineIndex, line) in slots.enumerated() {
            let y = h * (startY - (CGFloat(lineIndex) * step))
            let points = spread(line.count, y: y, width: w)
            for (slotIndex, position) in line.enumerated() {
                let point = points[slotIndex]
                openSlots.append((position, point))
            }
        }

        for (idx, player) in fieldPlayers.enumerated() {
            if idx < openSlots.count {
                assigned.append((player, openSlots[idx].0, openSlots[idx].1))
            }
        }

        return ZStack {
            if let gk {
                playerCircle(gk)
                    .position(CGPoint(x: w * 0.50, y: h * 0.86))
            }

            ForEach(Array(assigned.enumerated()), id: \.offset) { _, item in
                playerCircle(item.0)
                    .position(item.2)
            }
        }
    }

    private func spread(_ count: Int, y: CGFloat, width: CGFloat) -> [CGPoint] {
        guard count > 0 else { return [] }
        if count == 1 {
            return [CGPoint(x: width * 0.50, y: y)]
        }
        let sidePadding = max(18, width * 0.10)
        let usableWidth = width - (sidePadding * 2)
        let step = usableWidth / CGFloat(count - 1)
        return (0..<count).map { i in
            CGPoint(x: sidePadding + (CGFloat(i) * step), y: y)
        }
    }

    private func playerCircle(_ player: Player) -> some View {
        let name = store.displayName(for: player)
        let isSelected = selectedPlayerID == player.id
        let isGoalkeeper = store.activeGoalkeeper()?.id == player.id
        return VStack(spacing: 2) {
            Text("\(player.number)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .opacity(0.75)
        }
        .foregroundStyle(.primary)
        .frame(width: 48, height: 48)
        .background(
            Circle()
                .fill(.thinMaterial)
                .overlay(
                    Circle()
                        .fill(GoStatsTheme.teal.opacity(0.22))
                )
        )
        .overlay(
            Circle().stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
        .overlay(
            Circle()
                .stroke(isSelected ? GoStatsTheme.teal : Color.clear, lineWidth: 2)
        )
        .overlay(
            Circle()
                .stroke(isGoalkeeper ? Color.red : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityLabel("\(player.name) number \(player.number)")
        .contentShape(Circle())
        .onTapGesture {
            onSelectPlayer?(player)
        }
    }
}
