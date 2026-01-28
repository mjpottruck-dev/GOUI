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
                ColoredActionButton(title: "Shot", icon: "scope", color: .blue, action: onShot)

                ColoredActionButton(title: "Own Goal", icon: "exclamationmark.triangle.fill", color: .red, action: onOwnGoal)
                ColoredActionButton(title: "Card", icon: "rectangle.on.rectangle", color: .red, action: onCard)

                ColoredActionButton(title: "PK Attempt", icon: "circle.dashed", color: .blue, action: onPKAttempt)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - A button that cannot be “tinted blue” by parent styles
private struct ColoredActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .font(.headline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}


