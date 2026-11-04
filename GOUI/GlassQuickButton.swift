import SwiftUI

struct GlassQuickButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.custom("DM Sans", size: 16).weight(.medium))
                Text(title)
                    .font(.custom("DM Sans", size: 16).weight(.medium))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundStyle(GoStatsTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GoStatsTheme.rCard, style: .continuous)
                    .stroke(GoStatsTheme.cardBorder, lineWidth: GoStatsTheme.cardBorderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}

