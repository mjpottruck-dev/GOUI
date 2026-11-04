import SwiftUI

public enum GlassLevel { case surface, raised, focus }

public struct GlassCard<Content: View>: View {
    private let level: GlassLevel
    private let cornerRadius: CGFloat
    private let content: Content

    public init(level: GlassLevel = .surface,
                cornerRadius: CGFloat = GoStatsTheme.cardRadius,
                @ViewBuilder content: () -> Content) {
        self.level = level
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(GoStatsTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
    }
}
