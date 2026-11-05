import UIKit

/// Every vibration in the app goes through here, so Settings → Haptics
/// (on/off and strength) applies everywhere.
enum Haptics {
    static let enabledKey = "haptics_enabled"
    static let intensityKey = "haptics_intensity"

    /// On unless the coach turned it off.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// 0.2 (subtle) … 1.0 (strong). Default 0.8.
    static var intensity: CGFloat {
        let stored = UserDefaults.standard.object(forKey: intensityKey) as? Double ?? 0.8
        return CGFloat(min(max(stored, 0.2), 1.0))
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred(intensity: intensity)
    }

    static func light() { impact(.light) }
    static func medium() { impact(.medium) }
    static func heavy() { impact(.heavy) }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(type)
    }

    /// Distinct "undo" buzz
    static func undoBuzz() { notify(.success) }

    /// When user taps undo but there's nothing to undo
    static func undoEmpty() { notify(.warning) }

    /// For "bad" events like red card / conceded / own goal
    static func warning() { notify(.warning) }
}
