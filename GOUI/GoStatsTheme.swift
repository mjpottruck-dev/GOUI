import SwiftUI
import UIKit

public enum GoStatsTheme {
    // MARK: - Brand (only used inside MatchView)
    public static let accent = Color(hex: "E8621A")
    public static let positive = Color(hex: "22C55E")
    public static let greenTint = Color(hex: "F0FDF4")
    public static let redTint = Color(hex: "FEF2F2")

    // MARK: - Progress Ring Colors (stats only)
    public static let ringGoals = Color(hex: "22C55E")
    public static let ringAssists = Color(hex: "3B82F6")
    public static let ringShots = Color(hex: "F59E0B")
    public static let ringConceded = Color(hex: "EF4444")
    public static let ringTrack = Color(hex: "f0f0f0")

    // MARK: - Page Background
    public static let bg = Color(hex: "f7f7f7")

    // MARK: - Card System (Cal AI style)
    public static let cardBg = Color.white
    public static let cardRadius: CGFloat = 20
    public static let cardPadding: CGFloat = 20
    public static let cardMargin: CGFloat = 16
    public static let cardGap: CGFloat = 12
    public static let cardShadowColor = Color.black.opacity(0.06)
    public static let cardShadowRadius: CGFloat = 12
    public static let cardShadowY: CGFloat = 2
    public static let cardBorder = Color(hex: "efefef")
    public static let cardBorderWidth: CGFloat = 0

    // MARK: - Score Card (MatchView only)
    public static let scoreBg = Color(hex: "1a1a1a")
    public static let scoreText = Color.white
    public static let scoreMuted = Color.white.opacity(0.6)

    // MARK: - Text
    public static let textPrimary = Color(hex: "1a1a1a")
    public static let textMuted = Color(hex: "aaaaaa")
    public static let text = Color(hex: "1a1a1a")
    public static let text2 = Color(hex: "aaaaaa")

    // MARK: - Dividers
    public static let divider = Color(hex: "efefef")
    public static let dividerWidth: CGFloat = 0.5

    // MARK: - Surfaces
    public static let surface = Color(hex: "f0f0f0")
    public static let pillActive = Color(hex: "1a1a1a")
    public static let pillInactive = Color.white

    // MARK: - Control Buttons (MatchView)
    public static let controlGray = Color(hex: "888888")

    // MARK: - Section Headers: 10px uppercase, letter-spacing 1px, #aaa
    public static let sectionHeaderColor = Color(hex: "aaaaaa")

    // MARK: - Empty State
    public static let emptyStateColor = Color(hex: "aaaaaa")

    // MARK: - Stats Season Card
    public static let seasonCardBg = Color(hex: "f0ebe4")

    // MARK: - Legacy aliases
    public static let teal = Color(hex: "0f0f0f")
    public static let uiGray = Color(uiColor: .separator)
    public static let uiGray2 = Color(uiColor: .tertiaryLabel)
    public static let stroke = Color(hex: "efefef")
    public static let rCard: CGFloat = 20
    public static let rButton: CGFloat = 20
    public static let rChip: CGFloat = 20

    // MARK: - Spacing
    public static let s8: CGFloat = 8
    public static let s12: CGFloat = 12
    public static let s16: CGFloat = 16
    public static let s20: CGFloat = 20
    public static let s24: CGFloat = 24

    // MARK: - Motion
    public static let motion = Animation.easeOut(duration: 0.16)

    // MARK: - Haptics
    public static func hapticTap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    // MARK: - Font Names
    public static let dmSansRegular = "DMSans-Regular"
    public static let dmSansMedium = "DMSans-Medium"
    public static let dmMono = "DMMono-Regular"

    // MARK: - Font Helpers
    public static func fontRegular(size: CGFloat) -> Font {
        .custom("DM Sans", size: size).weight(.regular)
    }
    public static func fontMedium(size: CGFloat) -> Font {
        .custom("DM Sans", size: size).weight(.medium)
    }
    public static func fontMono(size: CGFloat) -> Font {
        .custom("DM Mono", size: size)
    }

    // MARK: - Section Header
    public static func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(sectionHeaderColor)
    }

    // MARK: - Card view builder
    public static func card<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .padding(cardPadding)
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: cardShadowColor, radius: cardShadowRadius, x: 0, y: cardShadowY)
            )
    }
}

// MARK: - Reusable Card Modifier
public struct CardModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: GoStatsTheme.cardShadowColor,
                            radius: GoStatsTheme.cardShadowRadius,
                            x: 0, y: GoStatsTheme.cardShadowY)
            )
    }
}

// MARK: - Hex Color Helper
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255, green: Double(g) / 255,
                  blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
