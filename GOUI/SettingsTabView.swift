import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Settings (optional)")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

