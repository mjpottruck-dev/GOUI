import SwiftUI

/// Floating Liquid Glass tab bar. The selected tab sits in a glass pill that
/// slides between tabs: tap a tab, or press and drag across the bar and the pill
/// follows your finger (lifting like the system slider's knob), ticks as it passes
/// each tab, and snaps to the nearest one when you let go.
/// On iOS 26+ this uses real Liquid Glass; earlier versions fall back to material.
struct GlassTabBar<Tab: Hashable>: View {
    struct Item {
        let tab: Tab
        let title: String
        let icon: String
    }

    let items: [Item]
    @Binding var selected: Tab

    /// Finger position while dragging; nil when not touching.
    @State private var dragX: CGFloat? = nil
    @State private var hoveredIndex: Int? = nil

    private let barHeight: CGFloat = 62
    private let inset: CGFloat = 4

    private var selectedIndex: Int {
        items.firstIndex(where: { $0.tab == selected }) ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(max(items.count, 1))
            let tabWidth = geo.size.width / count
            let restingX = CGFloat(selectedIndex) * tabWidth
            let pillX = min(max((dragX.map { $0 - tabWidth / 2 }) ?? restingX, 0), geo.size.width - tabWidth)
            let activeIndex = hoveredIndex ?? selectedIndex

            ZStack(alignment: .leading) {
                pill
                    .frame(width: tabWidth - inset * 2, height: geo.size.height - inset * 2)
                    .scaleEffect(dragX == nil ? 1 : 1.12) // lifts while dragging
                    .offset(x: pillX + inset)
                    .animation(.spring(response: 0.32, dampingFraction: 0.78), value: pillX)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: dragX == nil)

                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        label(item, isActive: index == activeIndex)
                            .frame(width: tabWidth, height: geo.size.height)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(item.title)
                            .accessibilityAddTraits(item.tab == selected ? [.isButton, .isSelected] : .isButton)
                            .accessibilityAction { select(index) }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = value.location.x
                        // Only start sliding once the finger actually moves (a tap
                        // shouldn't make the pill jump under the finger first).
                        if dragX != nil || abs(value.translation.width) > 6 {
                            dragX = x
                        }
                        let index = clampedIndex(for: x, tabWidth: tabWidth)
                        if index != hoveredIndex {
                            if hoveredIndex != nil { Haptics.light() } // tick per tab
                            hoveredIndex = index
                        }
                    }
                    .onEnded { value in
                        let index = clampedIndex(for: value.location.x, tabWidth: tabWidth)
                        select(index)
                        dragX = nil
                        hoveredIndex = nil
                    }
            )
        }
        .frame(height: barHeight)
        .padding(inset)
        .background(barBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    // MARK: - Pieces

    private func label(_ item: Item, isActive: Bool) -> some View {
        VStack(spacing: 3) {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                .symbolEffect(.bounce, value: isActive && item.tab == selected)
            Text(item.title)
                .font(.system(size: 10, weight: isActive ? .semibold : .medium))
        }
        .foregroundStyle(isActive ? GoStatsTheme.textPrimary : GoStatsTheme.textPrimary.opacity(0.45))
        .animation(.easeOut(duration: 0.15), value: isActive)
    }

    @ViewBuilder
    private var pill: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(Color.clear)
                .glassEffect(.regular.tint(Color.white.opacity(0.35)).interactive(), in: Capsule())
                .shadow(color: .black.opacity(dragX == nil ? 0.06 : 0.16), radius: dragX == nil ? 4 : 10, y: 2)
        } else {
            Capsule()
                .fill(Color.black.opacity(0.07))
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var barBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(Color.clear)
                .glassEffect(.regular, in: Capsule())
                .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
        }
    }

    // MARK: - Helpers

    private func clampedIndex(for x: CGFloat, tabWidth: CGFloat) -> Int {
        guard tabWidth > 0 else { return selectedIndex }
        return min(max(Int(x / tabWidth), 0), items.count - 1)
    }

    private func select(_ index: Int) {
        guard items.indices.contains(index) else { return }
        if items[index].tab != selected { Haptics.light() }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selected = items[index].tab
        }
    }
}
