import SwiftUI

public struct BottomActionTray<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GlassCard(level: .surface, cornerRadius: 20) {
            content
        }
        .padding(.horizontal, GoStatsTheme.s16)
        .padding(.bottom, GoStatsTheme.s16)
    }
}

