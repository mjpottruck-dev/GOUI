import SwiftUI

public enum GlassLevel {
    case surface     // light
    case raised      // medium
    case focus       // heavier for modals/sheets
}

public struct GlassCard<Content: View>: View {
    private let level: GlassLevel
    private let cornerRadius: CGFloat
    private let content: Content
    @Environment(\.colorScheme) private var scheme

    public init(level: GlassLevel = .surface,
                cornerRadius: CGFloat = GoStatsTheme.rCard,
                @ViewBuilder content: () -> Content) {
        self.level = level
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        let material: Material = {
            switch level {
            case .surface: return .ultraThinMaterial
            case .raised:  return .thinMaterial
            case .focus:   return .regularMaterial
            }
        }()

        content
            .padding(GoStatsTheme.s16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .overlay(
                        // subtle white tint (keeps it “glass”, not fog)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(overlayOpacity))
                    )
                    .overlay(
                        // soft edge highlight
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(GoStatsTheme.stroke.opacity(borderOpacity), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(shadowOpacity),
                            radius: level == .focus ? 18 : 12,
                            x: 0, y: level == .focus ? 10 : 6)
            )
    }

    private var overlayOpacity: Double {
        switch level {
        case .focus:
            return scheme == .dark ? 0.08 : 0.12
        case .raised:
            return scheme == .dark ? 0.05 : 0.08
        case .surface:
            return scheme == .dark ? 0.04 : 0.06
        }
    }

    private var borderOpacity: Double {
        switch level {
        case .focus:
            return scheme == .dark ? 0.65 : 0.45
        case .raised, .surface:
            return scheme == .dark ? 0.45 : 0.30
        }
    }

    private var shadowOpacity: Double {
        scheme == .dark ? 0.35 : 0.10
    }
}
