import SwiftUI

struct FieldPlayerPickerView: View {
    let title: String
    let subtitle: String
    let players: [Player]
    let fieldStore: MatchStore?
    let allowNone: Bool
    let noneTitle: String
    let onPickPlayer: (Player) -> Void
    let onPickNone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            List {
                if let fieldStore {
                    FieldView1443(store: fieldStore, onSelectPlayer: { player in
                        onPickPlayer(player)
                    })
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if allowNone {
                    Button(noneTitle.isEmpty ? "None" : noneTitle) { onPickNone() }
                }

                ForEach(players) { p in
                    Button {
                        onPickPlayer(p)
                    } label: {
                        HStack {
                            Text("#\(p.number)")
                                .font(.headline)
                                .frame(width: 52, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name)
                                Text(p.position.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                }
            }
            .safeAreaInset(edge: .top) {
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 6)
                }
            }
        }
    }
}
