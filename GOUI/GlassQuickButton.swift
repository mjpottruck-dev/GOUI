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
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .modifier(GlassOnlyButtonModifier(tint: tint))
    }
}

private struct GlassOnlyButtonModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        // IMPORTANT:
        // Liquid Glass only exists in the iOS 18 / Xcode 16 SDK.
        // If you're not on that SDK, this file MUST compile without referencing glassEffect at all.

        #if swift(>=6.0)
        if #available(iOS 18.0, *) {
            // This will ONLY compile if your Xcode has the iOS 18 SDK.
            return AnyView(
                content
                    .glassEffect(.regular.tint(tint).interactive(), in: .capsule)
            )
        } else {
            return AnyView(fallback(content))
        }
        #else
        return AnyView(fallback(content))
        #endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(.thinMaterial, in: Capsule())
            .overlay(
                Capsule().stroke(tint.opacity(0.35), lineWidth: 1)
            )
    }
}

