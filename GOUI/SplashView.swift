import SwiftUI

struct SplashView: View {
    let onSkip: () -> Void

    @State private var ballScale: CGFloat = 0.5
    @State private var ballOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            GoStatsTheme.textPrimary.ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "soccerball")
                    .font(.system(size: 80, weight: .regular))
                    .foregroundStyle(.white)
                    .scaleEffect(ballScale)
                    .opacity(ballOpacity)

                Text("GoalStats")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Text("Track. Analyze. Win.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            runAnimationSequence()
        }
        .onTapGesture(count: 3) {
            #if DEBUG
            onSkip()
            #endif
        }
    }

    private func runAnimationSequence() {
        // Step 1: Soccer ball bounces in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            ballScale = 1.0
            ballOpacity = 1.0
        }

        // Step 2: Title fades in + slides up (0.3s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }

        // Step 3: Tagline fades in (0.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                taglineOpacity = 1.0
            }
        }

        // Step 4: Hold, then dismiss (~2.5s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                onSkip()
            }
        }
    }
}
