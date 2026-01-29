import SwiftUI

struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Player) -> Void
    let sport: any SportDefinition

    var body: some View {
        CreatePlayerView(onCreate: { newPlayer in
            onCreate(newPlayer)
            dismiss()
        }, sport: sport)
    }
}
