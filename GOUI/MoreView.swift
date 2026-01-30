import SwiftUI

struct MoreView: View {
    @Bindable var teamStore: TeamStore
    @ObservedObject var clipStore: ClipStore
    let teamID: UUID?

    var body: some View {
        NavigationStack {
            List {
                Section("Tools") {
                    if let teamID {
                        NavigationLink("Export Center") {
                            ExportCenterView(teamStore: teamStore, teamID: teamID)
                        }
                    }
                }

                Section("Settings") {
                    NavigationLink("Settings") {
                        SettingsView(teamStore: teamStore, clipStore: clipStore)
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}
