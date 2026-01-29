import SwiftUI

struct CreatePlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Player) -> Void

    @State private var name: String = ""
    @State private var numberText: String = ""
    @State private var position: Position = .cm
    @State private var secondaryPosition: Position? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Info") {
                    TextField("Name", text: $name)

                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)

                    Picker("Primary Position", selection: $position) {
                        ForEach(Position.rosterPositions) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }

                    Picker("Secondary Position", selection: $secondaryPosition) {
                        Text("None").tag(Position?.none)
                        ForEach(Position.rosterPositions) { pos in
                            Text(pos.rawValue).tag(Optional(pos))
                        }
                    }
                }

                Section {
                    Button("Create Player") {
                        let trimmedNumber = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let number = Int(trimmedNumber) ?? 0
                        let jersey = trimmedNumber.isEmpty ? "\(number)" : trimmedNumber
                        let newPlayer = Player(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            number: number,
                            jersey: jersey,
                            position: position,
                            secondaryPosition: secondaryPosition
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
