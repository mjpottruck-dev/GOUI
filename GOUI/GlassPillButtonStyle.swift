import SwiftUI

struct GlassPillButtonStyle: ButtonStyle {

    var fill: Color = GoStatsTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.08 : 0.14),
                            radius: configuration.isPressed ? 6 : 10,
                            x: 0, y: configuration.isPressed ? 2 : 6)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

