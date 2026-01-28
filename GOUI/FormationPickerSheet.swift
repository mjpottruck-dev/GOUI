import SwiftUI

struct FormationPickerSheet: View {

    let onPick: (Formation) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Formation.allCases) { f in
                    Button {
                        onPick(f)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(f.rawValue)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
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

