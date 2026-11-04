import ActivityKit
import WidgetKit
import SwiftUI

struct GoalStatsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchActivityAttributes.self) { context in
            // Lock screen / banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.teamName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(context.state.opponentName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.homeScore) — \(context.state.awayScore)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(context.state.minute)")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.half)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        if !context.state.lastEvent.isEmpty {
                            Text(context.state.lastEvent)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        // Mic deep link button
                        Link(destination: URL(string: "goalstats://voice")!) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(.white.opacity(0.2)))
                        }
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                    Text("\(context.state.homeScore)-\(context.state.awayScore)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            } compactTrailing: {
                Text(context.state.minute)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            } minimal: {
                Image(systemName: "soccerball")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<MatchActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                // GoalStats icon
                Image(systemName: "soccerball")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                // Half label
                Text(context.state.half)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                // Mic button (deep link)
                Link(destination: URL(string: "goalstats://voice")!) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
            }

            // Team names and score
            HStack(spacing: 16) {
                // Home team
                VStack(spacing: 4) {
                    Text(context.state.teamName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)

                Text("—")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))

                // Away team
                VStack(spacing: 4) {
                    Text(context.state.opponentName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }

            // Time
            Text(context.state.minute)
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))

            // Last event
            if !context.state.lastEvent.isEmpty {
                Text(context.state.lastEvent)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.1)))
            }
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
}
