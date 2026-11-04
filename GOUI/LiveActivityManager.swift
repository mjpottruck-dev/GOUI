import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

/// Manages the Live Activity lifecycle for match tracking on the lock screen.
/// Thread-safe: callable from any context. Internal state is protected by a lock.
final class LiveActivityManager: @unchecked Sendable {
    static let shared = LiveActivityManager()

    private let lock = NSLock()
    #if canImport(ActivityKit) && os(iOS)
    private var _currentActivity: Activity<MatchActivityAttributes>?
    #endif
    private var _matchID: String?
    private var _hasActiveActivity: Bool = false

    private init() {}

    // MARK: - Start

    func startActivity(teamName: String, opponentName: String) {
        #if canImport(ActivityKit) && os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }

        // End any existing activity first
        endActivity()

        let id = UUID().uuidString

        let attributes = MatchActivityAttributes(matchID: id)
        let initialState = MatchActivityAttributes.ContentState(
            homeScore: 0,
            awayScore: 0,
            minute: "00:00",
            half: "1ST HALF",
            teamName: teamName,
            opponentName: opponentName,
            lastEvent: ""
        )

        do {
            let content = ActivityContent(state: initialState, staleDate: nil)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            lock.lock()
            _currentActivity = activity
            _matchID = id
            _hasActiveActivity = true
            lock.unlock()
            print("[LiveActivity] Started activity: \(activity.id)")
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
        #endif
    }

    // MARK: - Update

    func updateActivity(
        homeScore: Int,
        awayScore: Int,
        elapsedSeconds: Int,
        hasSplitHalf: Bool,
        teamName: String,
        opponentName: String,
        lastEvent: String = ""
    ) {
        #if canImport(ActivityKit) && os(iOS)
        lock.lock()
        let activity = _currentActivity
        lock.unlock()
        guard let activity else { return }

        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        let minuteStr = String(format: "%02d:%02d", minutes, seconds)
        let halfStr = hasSplitHalf ? "2ND HALF" : "1ST HALF"

        let state = MatchActivityAttributes.ContentState(
            homeScore: homeScore,
            awayScore: awayScore,
            minute: minuteStr,
            half: halfStr,
            teamName: teamName,
            opponentName: opponentName,
            lastEvent: lastEvent
        )

        Task {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
            print("[LiveActivity] Updated: \(homeScore)-\(awayScore) \(minuteStr)")
        }
        #endif
    }

    // MARK: - End

    func endActivity() {
        #if canImport(ActivityKit) && os(iOS)
        lock.lock()
        let activity = _currentActivity
        _currentActivity = nil
        _matchID = nil
        _hasActiveActivity = false
        lock.unlock()

        guard let activity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("[LiveActivity] Ended activity")
        }
        #endif
    }

    // MARK: - Check if active

    var isActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _hasActiveActivity
    }
}
