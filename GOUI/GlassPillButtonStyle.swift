import SwiftUI

struct GlassPillButtonStyle: ButtonStyle {

    var fill: Color = GoStatsTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                    .fill(fill)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

