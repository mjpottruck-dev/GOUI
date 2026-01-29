import SwiftUI

struct PlayerPickerSheet: View {

    let eventType: EventType
    @ObservedObject var store: MatchStore
    let onPick: (Player) -> Void

    var body: some View {
        PlayerFieldPicker(
            mode: .primary,
            store: store,
            title: "\(eventType.label) • Player"
        ) { p in
            onPick(p)
        }
    }
}
