import SwiftUI

struct MatchTimelineView: View {

    let events: [MatchEvent]
    let clipStore: ClipStore?
    let teamStore: TeamStore?
    let teamID: UUID?

    @State private var selectedEvent: MatchEvent? = nil

    init(events: [MatchEvent] = [], clipStore: ClipStore? = nil, teamStore: TeamStore? = nil, teamID: UUID? = nil) {
        self.events = events
        self.clipStore = clipStore
        self.teamStore = teamStore
        self.teamID = teamID
    }

    var body: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {

                Text("PLAY-BY-PLAY")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)

                if events.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)

                        Text("No events yet.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(events.sorted(by: { $0.seconds > $1.seconds })) { e in
                            Button {
                                selectedEvent = e
                            } label: {
                                row(e)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            if let clipStore, let teamStore, let teamID {
                ClipListView(
                    title: "Linked Clips",
                    clips: clipStore.linkedClips(for: event.id),
                    clipStore: clipStore,
                    teamStore: teamStore,
                    teamID: teamID
                )
            }
        }
    }

    private func row(_ e: MatchEvent) -> some View {
        HStack(spacing: 12) {
            Text(timeString(e.seconds))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
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

            if let clipStore, clipStore.linkedClips(for: e.id).isEmpty == false {
                Image(systemName: "film")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
            }

            Text(e.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.45))
        )
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}
