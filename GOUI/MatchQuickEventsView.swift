import SwiftUI

struct MatchQuickEventsView_Old: View {

    // MARK: - Actions (plug in your existing logic)
    let onGoal: () -> Void
    let onShot: () -> Void
    let onOwnGoal: () -> Void
    let onCard: () -> Void
    let onPKAttempt: () -> Void
    let onPKMade: () -> Void

    let onSave: () -> Void
    let onConceded: () -> Void
    let onPKSaved: () -> Void
    let onPKConceded: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Quick Events
            sectionTitle("Quick Events")
            grid {
                ColoredActionButton(title: "Goal", icon: "checkmark.seal.fill", color: .green, action: onGoal)
                ColoredActionButton(title: "Shot", icon: "scope", color: GoStatsTheme.primary, action: onShot)

                ColoredActionButton(title: "Own Goal", icon: "exclamationmark.triangle.fill", color: .red, action: onOwnGoal)
                ColoredActionButton(title: "Card", icon: "rectangle.on.rectangle", color: .red, action: onCard)

                ColoredActionButton(title: "PK Attempt", icon: "circle.dashed", color: GoStatsTheme.primary, action: onPKAttempt)
                ColoredActionButton(title: "PK Made", icon: "circle.fill", color: .green, action: onPKMade)
            }

            // Keeper Quick Events
            sectionTitle("Keeper Quick Events")
            grid {
                ColoredActionButton(title: "Save", icon: "hand.raised.fill", color: .green, action: onSave)
                ColoredActionButton(title: "Conceded", icon: "xmark.seal.fill", color: .red, action: onConceded)

                ColoredActionButton(title: "PK Saved", icon: "shield.fill", color: .green, action: onPKSaved)
                ColoredActionButton(title: "PK Conceded", icon: "shield.slash.fill", color: .red, action: onPKConceded)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous))
    }

    // MARK: - Layout helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func grid(@ViewBuilder _ content: () -> some View) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            content()
        }
    }
}

// MARK: - Event button: white bg + thin border + dark text; Goal gets filled dark bg
private struct ColoredActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    private var isGoal: Bool { title == "Goal" }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.custom("DM Sans", size: 16).weight(.medium))
            Text(title)
                .font(.custom("DM Sans", size: 16).weight(.medium))
        }
        .foregroundStyle(isGoal ? .white : GoStatsTheme.text)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .fill(isGoal ? GoStatsTheme.positive : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                .stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
        )
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}

