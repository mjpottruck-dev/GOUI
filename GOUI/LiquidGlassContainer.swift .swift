import SwiftUI
import UIKit

// MARK: - iOS 26 "Liquid Glass" Container (Dark Mode compatible)
//
// Drop-in reusable glass card / button container.
// - Uses system Material (blurs content behind)
// - Translucent tint that adapts to light/dark mode
// - Subtle inner highlight + inner shadow to feel like floating glass
// - Works great as a Card, Bottom Tray, or Button background

public struct LiquidGlassContainer<Content: View>: View {
    private let cornerRadius: CGFloat
    private let material: Material
    private let contentPadding: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = 16,
        material: Material = .ultraThinMaterial,
        contentPadding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.contentPadding = contentPadding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(contentPadding)
            .background(glassBase)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(glassBorder)
            .overlay(innerHighlight)
            .overlay(innerShadow)
            .shadow(color: outerShadowColor, radius: 14, x: 0, y: 8)
            .accessibilityAddTraits(.isButton) // harmless for cards; helpful if used as button container
    }

    // MARK: - Base material + adaptive tint
    @Environment(\.colorScheme) private var scheme

    private var glassBase: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(material) // <- blur + translucency
            .overlay(
                // adaptive tint layer (keeps it "glass", not "fog")
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(glassTintColor)
                    .opacity(glassTintOpacity)
            )
    }

    // MARK: - Border (quiet, Apple-clean)
    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderColor, lineWidth: 1)
            .blendMode(.overlay)
    }

    // MARK: - Inner highlight (top-left sheen)
    private var innerHighlight: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(scheme == .dark ? 0.18 : 0.22),
                        Color.white.opacity(0.00),
                        Color.white.opacity(0.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .blendMode(.screen)
            .padding(1)
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }

    // MARK: - Inner shadow (bottom-right depth)
    private var innerShadow: some View {
        // Inner shadow trick: stroke + blur + offset + masked to inside
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.black.opacity(scheme == .dark ? 0.55 : 0.28), lineWidth: 2)
            .blur(radius: 3)
            .offset(x: 0, y: 2)
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .padding(1)
            .blendMode(.multiply)
    }

    // MARK: - Adaptive colors
    private var glassTintColor: Color {
        // Slight “milk glass” tint that adapts
        scheme == .dark ? Color.white : Color.white
    }

    private var glassTintOpacity: Double {
        // More tint in dark mode to keep legibility; less in light mode to keep it airy
        scheme == .dark ? 0.10 : 0.06
    }

    private var borderColor: Color {
        scheme == .dark
            ? Color.white.opacity(0.14)
            : Color.black.opacity(0.06)
    }

    private var outerShadowColor: Color {
        scheme == .dark
            ? Color.black.opacity(0.50)
            : Color.black.opacity(0.10)
    }
}

// MARK: - Liquid Glass Button (uses the same container)

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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            LiquidGlassContainer(cornerRadius: 14, material: .thinMaterial, contentPadding: 12) {
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
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

// MARK: - Press animation style (subtle, Apple-clean)

public struct PressableScale: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

// MARK: - Demo Preview (delete if you want)

struct LiquidGlassDemoView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [GoStatsTheme.primary.opacity(0.25), .mint.opacity(0.25), .purple.opacity(0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                LiquidGlassContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Liquid Glass Card")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Translucent • Blurs background • Inner highlight & shadow")
                            .font(.system(size: 13))
                            .opacity(0.75)
                    }
                    .foregroundStyle(.primary)
                }

                HStack(spacing: 12) {
                    LiquidGlassButton("Undo", systemImage: "arrow.uturn.backward", style: .neutral) {}
                    LiquidGlassButton("Sub", systemImage: "arrow.triangle.2.circlepath", style: .primary(accent: .mint)) {}
                }
            }
            .padding()
        }
    }
}

#Preview {
    LiquidGlassDemoView()
        .preferredColorScheme(.light)

    LiquidGlassDemoView()
        .preferredColorScheme(.dark)
}
