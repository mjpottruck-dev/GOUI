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
                        .font(.custom("DM Sans", size: 10).weight(.medium))
                        .tracking(1)
                        .foregroundStyle(GoStatsTheme.sectionHeaderColor)

                    Spacer()

                    Text(timeText)
                        .font(.custom("DM Mono", size: 14))
                        .foregroundStyle(GoStatsTheme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .fill(GoStatsTheme.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                                .stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
                        )
                }

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(homeName)
                            .font(.custom("DM Sans", size: 15).weight(.medium))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("Home")
                            .font(.custom("DM Sans", size: 12))
                            .foregroundStyle(GoStatsTheme.text2)
                    }

                    Spacer()

                    Text("\(homeScore)")
                        .font(.custom("DM Mono", size: 40))
                        .foregroundStyle(GoStatsTheme.text)

                    Text("—")
                        .font(.custom("DM Sans", size: 26).weight(.medium))
                        .foregroundStyle(GoStatsTheme.text2)
                        .padding(.horizontal, 6)

                    Text("\(awayScore)")
                        .font(.custom("DM Mono", size: 40))
                        .foregroundStyle(GoStatsTheme.text)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(awayName)
                            .font(.custom("DM Sans", size: 15).weight(.medium))
                            .foregroundStyle(GoStatsTheme.text)
                        Text("Away")
                            .font(.custom("DM Sans", size: 12))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }

                Divider()
                    .overlay(GoStatsTheme.cardBorder)

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
                .font(.custom("DM Sans", size: 10).weight(.medium))
                .tracking(1)
                .foregroundStyle(GoStatsTheme.sectionHeaderColor)
            Text(value)
                .font(.custom("DM Mono", size: 18))
                .foregroundStyle(GoStatsTheme.text)
        }
    }
}
