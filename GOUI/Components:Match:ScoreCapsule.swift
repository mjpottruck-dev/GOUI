import SwiftUI

public struct ScoreCapsule: View {
    public let homeName: String
    public let awayName: String
    public let homeScore: Int
    public let awayScore: Int
    public let timeText: String
    public let kpiLeftTitle: String
    public let kpiLeftValue: String
    public let kpiRightTitle: String
    public let kpiRightValue: String

    public init(homeName: String,
                awayName: String,
                homeScore: Int,
                awayScore: Int,
                timeText: String,
                kpiLeftTitle: String,
                kpiLeftValue: String,
                kpiRightTitle: String,
                kpiRightValue: String) {
        self.homeName = homeName
        self.awayName = awayName
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.timeText = timeText
        self.kpiLeftTitle = kpiLeftTitle
        self.kpiLeftValue = kpiLeftValue
        self.kpiRightTitle = kpiRightTitle
        self.kpiRightValue = kpiRightValue
    }

    public var body: some View {
        GlassCard(level: .raised) {
            VStack(alignment: .leading, spacing: GoStatsTheme.s12) {

                HStack(alignment: .firstTextBaseline) {
                    Text("MATCH")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)

                    Spacer()

                    Text(timeText)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rChip, style: .continuous)
                                .fill(GoStatsTheme.teal.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rChip, style: .continuous)
                                .stroke(GoStatsTheme.teal.opacity(0.20), lineWidth: 1)
                        )
                }

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(homeName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("Home")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(GoStatsTheme.text2)
                    }

                    Spacer()

                    Text("\(homeScore)")
                        .font(.system(size: 40, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text)

                    Text("—")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                        .padding(.horizontal, 6)

                    Text("\(awayScore)")
                        .font(.system(size: 40, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GoStatsTheme.text)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(awayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("Away")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                Divider()
                    .overlay(GoStatsTheme.uiGray.opacity(0.7))

                HStack(spacing: GoStatsTheme.s16) {
                    kpi(title: kpiLeftTitle, value: kpiLeftValue)
                    Spacer()
                    kpi(title: kpiRightTitle, value: kpiRightValue)
                }
            }
        }
    }

    private func kpi(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(GoStatsTheme.text)
        }
    }
}

