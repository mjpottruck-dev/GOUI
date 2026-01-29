import Foundation

enum DebugSettings {
    static let renderCountKey = "debug.renderCounts.enabled"
    static let skipSplashKey = "debug.splash.skip"

    static var renderCountsEnabled: Bool {
        UserDefaults.standard.bool(forKey: renderCountKey)
    }

    static var skipSplashEnabled: Bool {
        UserDefaults.standard.bool(forKey: skipSplashKey)
    }

    static func setRenderCountsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: renderCountKey)
    }

    static func setSkipSplashEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: skipSplashKey)
    }
}

enum DebugRenderLogger {
    private static var counts: [String: Int] = [:]

    static func log(_ name: String, enabled: Bool) {
        guard enabled else { return }
        counts[name, default: 0] += 1
        print("🔁 Render \(name): \(counts[name] ?? 0)")
    }
}
