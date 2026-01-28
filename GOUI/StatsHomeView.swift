import SwiftUI

struct StatsHomeView: View {

    @State var teamStore: TeamStore

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            VStack(spacing: 16) {
                LiquidGlassContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STATS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)

                        Text("Stats Overview v2 is next.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)

                        Text("We removed the old TeamArchiveView dependency.")
                            .font(.system(size: 13))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 16)
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

