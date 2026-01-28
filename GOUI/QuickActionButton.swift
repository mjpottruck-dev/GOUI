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
            return .green
        case .ownGoal, .card, .conceded, .pkConceded:
            return .red
        case .shot, .pkAttempt:
            return .blue
        }
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    let kind: QuickActionKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(kind.tint.opacity(configuration.isPressed ? 0.70 : 0.90))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}


