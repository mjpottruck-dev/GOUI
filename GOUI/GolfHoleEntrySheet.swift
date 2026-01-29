import SwiftUI

struct GolfHoleEntrySheet: View {
    @ObservedObject var store: MatchStore
    let player: Player
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var holeNumber: Int = 1
    @State private var strokes: Int = 4
    @State private var putts: Int = 0
    @State private var includePutts: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Hole") {
                    Stepper("Hole \(holeNumber)", value: $holeNumber, in: 1...max(storeHoleCount, 1))
                }

                Section("Score") {
                    Stepper("Strokes: \(strokes)", value: $strokes, in: 1...20)
                    Toggle("Track Putts", isOn: $includePutts)
                    if includePutts {
                        Stepper("Putts: \(putts)", value: $putts, in: 0...10)
                    }
                }
            }
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDone()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.recordHoleScore(
                            player: player,
                            holeIndex: holeNumber - 1,
                            strokes: strokes,
                            putts: includePutts ? putts : nil
                        )
                        dismiss()
                        onDone()
                    }
                }
            }
        }
        .onAppear {
            if store.currentPeriodIndex + 1 <= storeHoleCount {
                holeNumber = max(1, store.currentPeriodIndex + 1)
            }
        }
    }

    private var storeHoleCount: Int {
        let fallback = store.sport.defaultHoleCount
        return store.playerHoleScores.values.first?.count ?? fallback
    }
}
