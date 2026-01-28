import SwiftUI

struct CreatePlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Player) -> Void

    @State private var name: String = ""
    @State private var numberText: String = ""
    @State private var position: Position = .mid

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Info") {
                    TextField("Name", text: $name)

                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)

                    Picker("Position", selection: $position) {
                        ForEach(Position.allCases) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }
                }

                Section {
                    Button("Create Player") {
                        let number = Int(numberText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                        let newPlayer = Player(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            number: number,
                            position: position
                        )
                        onCreate(newPlayer)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

