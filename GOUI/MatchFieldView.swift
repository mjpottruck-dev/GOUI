import SwiftUI

/// MatchFieldView — v2 field with player dots
/// - Uses store.players + store.onFieldIDs
/// - GK is forced into the bottom goal box visually
/// - Def/Mid/Fw arranged above
struct MatchFieldView: View {
    @ObservedObject var store: MatchStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let padding: CGFloat = 14

            ZStack {
                // Field base (kept simple + readable)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fieldFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(border, lineWidth: 1)
                    )

                // Mid line
                Rectangle()
                    .fill(border.opacity(0.45))
                    .frame(height: 1)
                    .padding(.horizontal, 22)

                // Bottom goal box (v2 requirement: goal box at bottom)
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(border.opacity(0.85), lineWidth: 1)
                        .frame(width: size.width * 0.55, height: size.height * 0.22)
                        .padding(.bottom, 18)
                }

                // Player dots
                playersLayer(in: size, padding: padding)
            }
            .padding(2)
        }
    }

    // MARK: - Players

    @ViewBuilder
    private func playersLayer(in size: CGSize, padding: CGFloat) -> some View {
        let onField = store.players.filter { store.onFieldIDs.contains($0.id) }

        let gk = onField.first(where: { $0.position == .gk })
        let defs = onField.filter { $0.position == .def }
        let mids = onField.filter { $0.position == .mid }
        let fws  = onField.filter { $0.position == .fw }

        // Lanes (top to bottom)
        let yTop: CGFloat = padding + 34
        let yFw: CGFloat  = yTop + 20
        let yMid: CGFloat = size.height * 0.42
        let yDef: CGFloat = size.height * 0.62
        let yGk: CGFloat  = size.height * 0.86 // inside goal box at bottom

        // GK
        if let gk {
            playerChip(gk)
                .position(x: size.width * 0.50, y: yGk)
        }

        // DEF/MID/FW distributed across width
        distributedRow(defs, y: yDef, width: size.width, sidePadding: 28)
        distributedRow(mids, y: yMid, width: size.width, sidePadding: 28)
        distributedRow(fws,  y: yFw,  width: size.width, sidePadding: 28)
    }

    private func distributedRow(_ players: [Player], y: CGFloat, width: CGFloat, sidePadding: CGFloat) -> some View {
        ZStack {
            if players.isEmpty { EmptyView() }
            else {
                ForEach(Array(players.enumerated()), id: \.element.id) { idx, p in
                    let n = players.count
                    let x = xPosition(index: idx, count: n, width: width, sidePadding: sidePadding)
                    playerChip(p)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func xPosition(index: Int, count: Int, width: CGFloat, sidePadding: CGFloat) -> CGFloat {
        if count == 1 { return width * 0.5 }
        let usable = width - (sidePadding * 2)
        let step = usable / CGFloat(count - 1)
        return sidePadding + (CGFloat(index) * step)
    }

    private func playerChip(_ player: Player) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(GoStatsTheme.teal.opacity(0.18))
                    .overlay(
                        Circle().stroke(GoStatsTheme.teal.opacity(0.35), lineWidth: 1)
                    )

                Text("\(player.number)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GoStatsTheme.text)
            }
            .frame(width: 42, height: 42)

            Text(player.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
                .lineLimit(1)
                .frame(width: 70)
        }
    }

    // MARK: - Field colors (dark mode safe)

    private var fieldFill: Color {
        // Slightly different field tint in dark vs light so it stays readable
        scheme == .dark
        ? Color.white.opacity(0.06)
        : Color.white.opacity(0.42)
    }

    private var border: Color {
        scheme == .dark
        ? Color.white.opacity(0.16)
        : Color.black.opacity(0.08)
    }
}

