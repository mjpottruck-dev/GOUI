import SwiftUI

struct EventFlowSheet: View {

    let eventType: EventType
    let onConfirm: (MatchAction) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var onTarget: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                VStack(spacing: 16) {
                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EVENT")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)

                            Text(eventType.label)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text)

                            if eventType.uiAction == .shot || eventType.uiAction == .shotPenalty {
                                Toggle("On Target", isOn: $onTarget)
                                    .tint(GoStatsTheme.teal)
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Text("Quick confirm")
                                    .font(.system(size: 13))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        GoStatsTheme.hapticTap()
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        GoStatsTheme.hapticTap()
                        var action = MatchAction(eventTypeID: eventType.id, seconds: 0)
                        if eventType.uiAction == .shot || eventType.uiAction == .shotPenalty { action.isOnTarget = onTarget }
                        onConfirm(action)
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
}
