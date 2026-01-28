import SwiftUI

struct NoTeamView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No Team Found")
                .font(.title2).bold()
            Text("Create a team first to start tracking matches.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

