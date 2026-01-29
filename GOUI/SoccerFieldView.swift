import SwiftUI

struct SoccerFieldView: View {
    @ObservedObject var store: MatchStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.green.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )

                // midfield line
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 1)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // bottom goal box
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    .frame(width: geo.size.width * 0.55, height: geo.size.height * 0.22)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.86)

                let onField = store.players.filter { store.onFieldIDs.contains($0.id) }

                ForEach(onField) { p in
                    playerBubble(p, fieldSize: geo.size)
                }
            }
        }
        .frame(height: 360)
    }

    private func playerBubble(_ p: Player, fieldSize: CGSize) -> some View {
        let pt: CGPoint = pointForPlayer(p, in: fieldSize)

        return VStack(spacing: 4) {
            Text("\(p.number)")
                .font(.headline)
            Text(p.name)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: 90)
        }
        .padding(10)
        .background(
            Circle()
                .fill(isGK(p) ? GoStatsTheme.primary.opacity(0.35) : Color.white.opacity(0.18))
        )
        .overlay(
            Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .position(pt)
    }

    private func pointForPlayer(_ p: Player, in size: CGSize) -> CGPoint {
        // Determine “row” based on position text (handles enum OR string)
        let posText = String(describing: p.position).uppercased()

        // GK bottom, DEF lower-mid, MID mid, FW upper
        let y: CGFloat
        if posText.contains("GK") {
            y = size.height * 0.84
        } else if posText.contains("DEF") {
            y = size.height * 0.68
        } else if posText.contains("MID") {
            y = size.height * 0.50
        } else if posText.contains("FW") || posText.contains("FWD") {
            y = size.height * 0.30
        } else {
            // unknown -> midfield
            y = size.height * 0.50
        }

        // Spread across 3 lanes deterministically by jersey number
        let lane = abs(p.number) % 3
        let xs: [CGFloat] = [0.28, 0.50, 0.72]
        let x = size.width * xs[lane]

        return CGPoint(x: x, y: y)
    }

    private func isGK(_ p: Player) -> Bool {
        String(describing: p.position).uppercased().contains("GK")
    }
}
