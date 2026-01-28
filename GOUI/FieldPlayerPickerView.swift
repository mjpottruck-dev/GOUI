import SwiftUI

struct FieldPlayerPickerView: View {
    let title: String
    let subtitle: String
    let players: [Player]
    let allowNone: Bool
    let noneTitle: String
    let onPickPlayer: (Player) -> Void
    let onPickNone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            List {
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

