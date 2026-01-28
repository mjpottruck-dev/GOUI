import SwiftUI

struct PlayerPickerSheet: View {

    let kind: MatchActionKind
    @ObservedObject var store: MatchStore
    let onPick: (Player) -> Void

    var body: some View {
        PlayerFieldPicker(
            mode: .primary,
            store: store,
            title: "\(kind.rawValue) • Player"
        ) { p in
            onPick(p)
        }
    }
}

