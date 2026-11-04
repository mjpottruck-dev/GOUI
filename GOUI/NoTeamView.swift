import SwiftUI

struct NoTeamView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No Team Found")
                .font(.custom("DM Sans", size: 17).weight(.medium))
            Text("Create a team first to start tracking matches.")
                .font(.custom("DM Sans", size: 13))
                .foregroundStyle(GoStatsTheme.emptyStateColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

