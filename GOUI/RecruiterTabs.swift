import SwiftUI

struct RecruiterSearchView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Search is coming soon.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Search")
        }
    }
}

struct RecruiterSavedPlayersView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Saved players will appear here.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Players")
        }
    }
}

struct RecruiterSavedTeamsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Saved teams will appear here.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Teams")
        }
    }
}
