import SwiftUI
import UIKit

// MARK: - Layered Card Container
// White card, 0.5pt border #e8e4df, 16px radius, subtle shadow

public struct LiquidGlassContainer<Content: View>: View {
    private let cornerRadius: CGFloat
    private let material: Material
    private let contentPadding: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = GoStatsTheme.cardRadius,
        material: Material = .ultraThinMaterial,
        contentPadding: CGFloat = GoStatsTheme.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.contentPadding = contentPadding
        self.content = content()
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        content
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
    }
}

// MARK: - Liquid Glass Button

public struct LiquidGlassButton: View {
    public enum Style {
        case primary(accent: Color)
        case neutral
    }

    private let title: String
    private let systemImage: String?
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, style: Style = .neutral, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            LiquidGlassContainer(cornerRadius: GoStatsTheme.cardRadius, material: .thinMaterial, contentPadding: 12) {
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.custom("DM Sans", size: 15).weight(.medium))
                    }
                    Text(title)
                        .font(.custom("DM Sans", size: 15).weight(.medium))
                        .lineLimit(1)
                }
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PressableScale())
    }

    @Environment(\.colorScheme) private var scheme

    private var foreground: Color {
        switch style {
        case .primary(let accent):
            return accent
        case .neutral:
            return scheme == .dark ? .white : .black
        }
    }
}

// MARK: - Press animation style

public struct PressableScale: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
