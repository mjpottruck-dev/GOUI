import SwiftUI

public struct Pressable: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(GoStatsTheme.motion, value: configuration.isPressed)
    }
}

