import SwiftUI

struct UpgradePromptView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text2)
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(GoStatsTheme.primary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
