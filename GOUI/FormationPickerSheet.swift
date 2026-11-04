import SwiftUI

struct FormationPickerSheet: View {

    let fieldSize: Int
    let onPick: (Formation) -> Void
    @Environment(\.dismiss) private var dismiss

    private var filteredFormations: [Formation] {
        Formation.allCases.filter { $0.playerCount == fieldSize }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFormations) { f in
                    Button {
                        onPick(f)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(f.rawValue)
                                    .font(.custom("DM Mono", size: 16))
                                Text(f.familyLabel)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .opacity(0.0001)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Choose Formation")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

