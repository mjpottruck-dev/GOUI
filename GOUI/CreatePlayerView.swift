import SwiftUI

struct CreatePlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Player) -> Void

    @State private var name: String = ""
    @State private var numberText: String = ""
    @State private var position: Position = .cm
    @State private var secondaryPosition: Position? = nil
    @State private var positionName: String = ""
    @State private var isGoalie: Bool = false
    @State private var notes: String = ""

    private let sport = SportDefinition.current

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Info") {
                    TextField("Name", text: $name)
                    if !isNameValid {
                        Text("Name is required.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)
                    if !isNumberValid {
                        Text("Number must be between 0 and 99.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if sport.supportsPositions {
                        Picker("Primary Position", selection: $position) {
                            ForEach(Position.rosterPositions) { pos in
                                Text(pos.rawValue).tag(pos)
                            }
                        }
                        .onChange(of: position) { _, newValue in
                            positionName = newValue.rawValue
                            if sport.supportsGoalie {
                                isGoalie = newValue == .gk
                            }
                        }

                        Picker("Secondary Position", selection: $secondaryPosition) {
                            Text("None").tag(Position?.none)
                            ForEach(Position.rosterPositions) { pos in
                                Text(pos.rawValue).tag(Optional(pos))
                            }
                        }
                    } else {
                        TextField("Position (optional)", text: $positionName)
                    }

                    if sport.supportsGoalie {
                        Toggle("Goalie", isOn: $isGoalie)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button("Create Player") {
                        let trimmedNumber = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let number = Int(trimmedNumber) ?? 0
                        let jersey = trimmedNumber.isEmpty ? "\(number)" : trimmedNumber
                        let resolvedPositionName = positionName.isEmpty ? position.rawValue : positionName
                        let newPlayer = Player(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            number: number,
                            jersey: jersey,
                            position: position,
                            secondaryPosition: secondaryPosition,
                            positionName: resolvedPositionName,
                            isGoalie: sport.supportsGoalie ? isGoalie : nil,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onCreate(newPlayer)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            positionName = position.rawValue
            if sport.supportsGoalie {
                isGoalie = position == .gk
            }
        }
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isNumberValid: Bool {
        let trimmed = numberText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed) else { return false }
        return (0...99).contains(value)
    }

    private var isFormValid: Bool {
        isNameValid && isNumberValid
    }
}
