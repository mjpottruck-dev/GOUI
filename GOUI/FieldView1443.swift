import SwiftUI

struct FieldView1443: View {
    @ObservedObject var store: MatchStore

    var body: some View {
        let onFieldPlayers = store.players.filter { store.onFieldIDs.contains($0.id) }

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Glass field card background (dark-mode safe)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Field surface
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                    .padding(10)

                // Lines
                fieldLines(size: CGSize(width: w, height: h))
                    .padding(10)

                // Players
                playersOverlay1443(players: onFieldPlayers, size: CGSize(width: w, height: h))
                    .padding(10)
            }
        }
        .frame(height: 360)
        .accessibilityLabel("Field view")
    }

    // MARK: - Field Lines (NO ViewBuilder)
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

            // Bottom goal box (your team defending)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                .frame(width: w * 0.42, height: h * 0.18)
                .position(x: w * 0.50, y: h * 0.82)

            // Top goal box (opponent)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                .frame(width: w * 0.42, height: h * 0.18)
                .position(x: w * 0.50, y: h * 0.18)
        }
    }

    // MARK: - Players Overlay (NO ViewBuilder)
    private func playersOverlay1443(players: [Player], size: CGSize) -> some View {
        let w = size.width
        let h = size.height

        let gk = players.first(where: { $0.position == .gk })
        let defs = players.filter { $0.position == .def }
        let mids = players.filter { $0.position == .mid }
        let fws  = players.filter { $0.position == .fw }

        func spread(_ count: Int, y: CGFloat) -> [CGPoint] {
            guard count > 0 else { return [] }
            return (0..<count).map { i in
                let t = CGFloat(i + 1) / CGFloat(count + 1)
                return CGPoint(x: w * (0.10 + 0.80 * t), y: y)
            }
        }

        let yGK  = h * 0.86
        let yDEF = h * 0.70
        let yMID = h * 0.52
        let yFW  = h * 0.34

        var placed: [(Player, CGPoint)] = []

        if let gk {
            placed.append((gk, CGPoint(x: w * 0.50, y: yGK)))
        }

        for (p, pt) in zip(defs.prefix(4), spread(4, y: yDEF)) { placed.append((p, pt)) }
        for (p, pt) in zip(mids.prefix(4), spread(4, y: yMID)) { placed.append((p, pt)) }
        for (p, pt) in zip(fws.prefix(3), spread(3, y: yFW)) { placed.append((p, pt)) }

        let usedIDs = Set(placed.map { $0.0.id })
        let extras = players.filter { !usedIDs.contains($0.id) }
        let extraPts = spread(extras.count, y: h * 0.18)
        for (p, pt) in zip(extras, extraPts) { placed.append((p, pt)) }

        return ZStack {
            ForEach(Array(placed.enumerated()), id: \.offset) { _, item in
                playerCircle(item.0)
                    .position(item.1)
            }
        }
    }

    private func playerCircle(_ player: Player) -> some View {
        return VStack(spacing: 2) {
            Text("\(player.number)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
            Text(player.position.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .opacity(0.75)
        }
        .foregroundStyle(.primary)
        .frame(width: 44, height: 44)
        .background(
            Circle().fill(.thinMaterial)
        )
        .overlay(
            Circle().stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityLabel("\(player.name) number \(player.number)")
    }
}
