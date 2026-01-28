import SwiftUI

struct TeamPickerSheet: View {

    var teamStore: TeamStore
    let onPick: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if teamStore.teams.isEmpty {
                    Text("No teams yet. Create one first.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(teamStore.teams) { team in
                        Button {
                            onPick(team.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(team.name)
                                        .foregroundStyle(.primary)
                                    Text("\(team.fieldSize)v\(team.fieldSize)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Select Team")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

