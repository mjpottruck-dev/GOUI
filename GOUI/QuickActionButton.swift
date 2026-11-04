import SwiftUI

enum QuickActionKind {
    case goal
    case shot
    case ownGoal
    case pkAttempt
    case card
    case save
    case pkSave
    case pkMade
    case conceded
    case pkConceded

    var tint: Color {
        switch self {
        case .goal, .save, .pkSave, .pkMade:
            return GoStatsTheme.positive
        case .ownGoal, .card, .conceded, .pkConceded:
            return .red
        case .shot, .pkAttempt:
            return GoStatsTheme.textPrimary
        }
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    let kind: QuickActionKind
    var isGoalButton: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("DM Sans", size: 16).weight(.medium))
            .foregroundColor(isGoalButton ? .white : GoStatsTheme.text)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                    .fill(isGoalButton
                          ? GoStatsTheme.positive.opacity(configuration.isPressed ? 0.80 : 1.0)
                          : Color.white.opacity(configuration.isPressed ? 0.90 : 1.0))
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                    .stroke(isGoalButton ? Color.clear : GoStatsTheme.cardBorder,
                            lineWidth: GoStatsTheme.cardBorderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}
