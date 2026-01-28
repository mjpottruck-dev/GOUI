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
                            .fill(Color.white.opacity(level == .focus ? 0.10 : 0.06))
                    )
                    .overlay(
                        // soft edge highlight
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(GoStatsTheme.uiGray.opacity(level == .focus ? 0.45 : 0.30), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.10),
                            radius: level == .focus ? 18 : 12,
                            x: 0, y: level == .focus ? 10 : 6)
            )
    }
}

