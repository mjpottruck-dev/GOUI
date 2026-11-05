import SwiftUI

// MARK: - Guided tour ("coach marks")
//
// Any view can be marked as a tour stop with `.tourAnchor(.startMatch)`. A screen
// then shows a sequence of steps with `.appTour(steps:isActive:)`: the screen dims,
// the current element is cut out and outlined, and a callout explains it.
// Tours run once per screen; Settings → "Replay App Tour" shows them again.

enum TourTarget: String, Hashable {
    // Home
    case teamPills, seasonRecord, shareRoster, startMatch
    case roster, seasonStats, playerStats, archive
    // Match
    case matchClock, teamEvents, keeperEvents, matchControls
}

struct TourStep: Identifiable {
    let id = UUID()
    let target: TourTarget
    let title: String
    let message: String
}

enum TourFlags {
    static let homeDoneKey = "tour_home_done"
    static let matchDoneKey = "tour_match_done"

    /// Makes every tour show again (Settings → Replay App Tour).
    static func resetAll() {
        UserDefaults.standard.set(false, forKey: homeDoneKey)
        UserDefaults.standard.set(false, forKey: matchDoneKey)
    }
}

struct TourAnchorKey: PreferenceKey {
    static var defaultValue: [TourTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TourTarget: Anchor<CGRect>], nextValue: () -> [TourTarget: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    /// Marks this view as something the guided tour can highlight.
    func tourAnchor(_ target: TourTarget) -> some View {
        // transform (not set) so anchors on views inside this one are kept too,
        // e.g. the Share button inside the Season Record card.
        transformAnchorPreference(key: TourAnchorKey.self, value: .bounds) { all, anchor in
            all[target] = anchor
        }
    }

    /// Shows the guided tour over this screen while `isActive` is true.
    func appTour(steps: [TourStep], isActive: Binding<Bool>, onFinish: @escaping () -> Void = {}) -> some View {
        overlayPreferenceValue(TourAnchorKey.self) { anchors in
            if isActive.wrappedValue {
                GeometryReader { proxy in
                    TourOverlay(
                        steps: steps.filter { anchors[$0.target] != nil },
                        frames: anchors.mapValues { proxy[$0] },
                        size: proxy.size,
                        onFinish: {
                            isActive.wrappedValue = false
                            onFinish()
                        }
                    )
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }
}

private struct TourOverlay: View {
    let steps: [TourStep]
    let frames: [TourTarget: CGRect]
    let size: CGSize
    let onFinish: () -> Void

    @State private var index = 0

    private var step: TourStep? { steps.indices.contains(index) ? steps[index] : nil }

    var body: some View {
        if let step, let target = frames[step.target] {
            let hole = target.insetBy(dx: -8, dy: -8)
            let calloutBelow = hole.midY < size.height * 0.55

            ZStack(alignment: .topLeading) {
                // Dim everything except the highlighted element.
                Path { p in
                    p.addRect(CGRect(origin: .zero, size: size))
                    p.addRoundedRect(in: hole, cornerSize: CGSize(width: 18, height: 18))
                }
                .fill(Color.black.opacity(0.62), style: FillStyle(eoFill: true))
                .contentShape(Rectangle())
                .onTapGesture { advance() } // tapping anywhere moves on

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: hole.width, height: hole.height)
                    .offset(x: hole.minX, y: hole.minY)
                    .allowsHitTesting(false)

                // Callout below the element if it's in the top half, otherwise above it.
                VStack(spacing: 0) {
                    if calloutBelow {
                        Color.clear.frame(height: hole.maxY + 14)
                        callout(step)
                        Spacer(minLength: 0)
                    } else {
                        Spacer(minLength: 0)
                        callout(step)
                        Color.clear.frame(height: max(0, size.height - hole.minY + 14))
                    }
                }
                .frame(maxWidth: 380)
                .padding(.horizontal, 16)
                .frame(width: size.width, height: size.height)
                .allowsHitTesting(true)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: index)
            // While the tour is up, VoiceOver stays on the tour, not the buttons behind it.
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        } else {
            Color.clear.onAppear { onFinish() }
        }
    }

    private func callout(_ step: TourStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(index + 1) of \(steps.count)")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(GoStatsTheme.textMuted)
            Text(step.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(GoStatsTheme.textPrimary)
            Text(step.message)
                .font(.system(size: 15))
                .foregroundStyle(GoStatsTheme.textPrimary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Skip tour") { onFinish() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GoStatsTheme.textMuted)
                Spacer()
                Button {
                    advance()
                } label: {
                    Text(index == steps.count - 1 ? "Got it" : "Next")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(GoStatsTheme.textPrimary))
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 6)
        )
    }

    private func advance() {
        Haptics.light()
        if index < steps.count - 1 {
            index += 1
        } else {
            onFinish()
        }
    }
}

// MARK: - Tour scripts

enum AppTours {
    static let home: [TourStep] = [
        TourStep(target: .teamPills, title: "Your teams",
                 message: "Switch between teams here. Tap + to add another team."),
        TourStep(target: .seasonRecord, title: "Season record",
                 message: "Wins, draws and losses update automatically after every saved match."),
        TourStep(target: .shareRoster, title: "Share a roster",
                 message: "Send your whole roster to another coach's phone nearby, like AirDrop."),
        TourStep(target: .startMatch, title: "Start a match",
                 message: "Opens the live match screen: clock, quick stats, subs and voice logging."),
        TourStep(target: .roster, title: "Roster",
                 message: "Add players, numbers and positions, set your starting lineup, or import a roster from a photo."),
        TourStep(target: .seasonStats, title: "Season stats",
                 message: "Team totals and leaders for the season, plus an AI season report."),
        TourStep(target: .playerStats, title: "Player stats",
                 message: "Every player's minutes, goals, assists, shots and saves."),
        TourStep(target: .archive, title: "Match archive",
                 message: "Every saved game. Open one to see the details, export it, or tap Edit to fix a mistake."),
    ]

    static let match: [TourStep] = [
        TourStep(target: .matchClock, title: "Clock and score",
                 message: "Start and pause the clock here. Pausing in the 1st half lets you call halftime. Tap the mic to log by voice: \"goal seven, assist ten\"."),
        TourStep(target: .matchControls, title: "Undo and subs",
                 message: "Undo the last action, make a substitution, or swap a whole line at once. Minutes are tracked for every player automatically."),
        TourStep(target: .teamEvents, title: "Log team events",
                 message: "Tap an event, then tap the player on the field. Goals ask for an assist next."),
        TourStep(target: .keeperEvents, title: "Keeper events",
                 message: "Saves and goals against go to the keeper on the field. With no keeper, Conceded still counts the goal."),
    ]
}
