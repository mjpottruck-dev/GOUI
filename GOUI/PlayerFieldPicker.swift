import SwiftUI

struct PlayerFieldPicker: View {

    // ✅ Keeps compatibility with old references: MatchView.PickerMode
    let mode: MatchView.PickerMode

    @ObservedObject var store: MatchStore
    let title: String
    let onPick: (Player) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        mode: MatchView.PickerMode = .primary,
        store: MatchStore,
        title: String = "Pick Player",
        onPick: @escaping (Player) -> Void
    ) {
        self.mode = mode
        self.store = store
        self.title = title
        self.onPick = onPick
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PLAYERS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text2)

                                ForEach(store.players) { p in
                                    Button {
                                        GoStatsTheme.hapticTap()
                                        onPick(p)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Text("#\(p.number)")
                                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                                .foregroundStyle(GoStatsTheme.text2)
                                                .frame(width: 50, alignment: .leading)

                                            Text(p.name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(GoStatsTheme.text)

                                            Spacer()

                                            Text(p.position.rawValue)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(GoStatsTheme.text2)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)

                                    Divider().opacity(0.35)
                                }
                            }
                        }

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 140)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

