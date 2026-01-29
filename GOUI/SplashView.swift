import SwiftUI

struct SplashView: View {
    let onSkip: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)
                    .scaleEffect(animate ? 1.05 : 0.95)
                    .opacity(animate ? 1 : 0.85)

                Text("GoStats")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(GoStatsTheme.text)

                Text("Leveling up your squad data")
                    .font(.footnote)
                    .foregroundStyle(GoStatsTheme.text2)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .onTapGesture(count: 3) {
            #if DEBUG
            onSkip()
            #endif
        }
    }
}
