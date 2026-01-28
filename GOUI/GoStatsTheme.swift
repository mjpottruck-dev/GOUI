import SwiftUI
import UIKit

public enum GoStatsTheme {
    // MARK: - Brand
    public static let teal = Color(hex: "#0ABAB5")

    // MARK: - Adaptive Backgrounds (Dark Mode compatible)
    // Use system backgrounds so it looks native in light/dark automatically.
    public static let bg = Color(uiColor: .systemGroupedBackground)
    public static let surface = Color(uiColor: .secondarySystemGroupedBackground)

    // MARK: - Neutrals
    public static let uiGray = Color(hex: "#D9DEE3")
    public static let uiGray2 = Color(hex: "#AEB8BF")

    // MARK: - Adaptive Text (Dark Mode compatible)
    public static let text = Color(uiColor: .label)
    public static let text2 = Color(uiColor: .secondaryLabel)

    // MARK: - Radii
    public static let rCard: CGFloat = 16
    public static let rButton: CGFloat = 14
    public static let rChip: CGFloat = 12

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
}

// MARK: - Hex Color Helper
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

