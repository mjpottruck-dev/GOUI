import SwiftUI

struct MatchTimelineView: View {

    let events: [MatchEvent]

    init(events: [MatchEvent] = []) {
        self.events = events
    }

    var body: some View {
        LiquidGlassContainer(cornerRadius: GoStatsTheme.rCard) {
            VStack(alignment: .leading, spacing: 12) {

                Text("PLAY-BY-PLAY")
                    .font(.custom("DM Sans", size: 10).weight(.medium)).tracking(1)
                    .foregroundStyle(GoStatsTheme.text2)

                if events.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.emptyStateColor)

                        Text("No events yet.")
                            .font(.custom("DM Sans", size: 13))
                            .foregroundStyle(GoStatsTheme.emptyStateColor)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(events.sorted(by: { $0.seconds > $1.seconds })) { e in
                            row(e)
                        }
                    }
                }
            }
        }
    }

    private func row(_ e: MatchEvent) -> some View {
        HStack(spacing: 12) {
            Text(timeString(e.seconds))
                .font(.custom("DM Mono", size: 13))
                .foregroundStyle(GoStatsTheme.text2)
                .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(e.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                if let d = e.detail, !d.isEmpty {
                    Text(d)
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }

            Spacer()

            Text(e.kind.rawValue)
                .font(.custom("DM Sans", size: 10).weight(.medium)).tracking(1)
                .foregroundStyle(GoStatsTheme.text2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.45))
        )
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}
