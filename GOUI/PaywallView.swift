import StoreKit
import SwiftUI

/// GoalStats Pro paywall: perks, yearly/monthly plans, subscribe, restore.
struct PaywallView: View {
    /// The feature the coach tapped, shown first and highlighted.
    var highlight: ProFeature? = nil
    /// Set when shown via Paywall.show (UIKit presentation).
    var onClose: (() -> Void)? = nil

    @ObservedObject private var pro = ProStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var selectedID: String = ProStore.yearlyID

    private var orderedPerks: [ProFeature] {
        guard let highlight else { return ProFeature.allCases }
        return [highlight] + ProFeature.allCases.filter { $0 != highlight }
    }

    private var selectedProduct: Product? {
        pro.products.first { $0.id == selectedID }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    perksCard
                    plans
                    if let error = pro.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(GoStatsTheme.ringConceded)
                            .multilineTextAlignment(.center)
                    }
                    Spacer(minLength: 150)
                }
                .padding(.horizontal, GoStatsTheme.cardMargin)
                .padding(.top, 28)
            }

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GoStatsTheme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white))
            }
            .accessibilityLabel("Close")
            .padding(16)
        }
        .safeAreaInset(edge: .bottom) { footer }
        .task { await pro.loadProducts() }
        .onChange(of: pro.isPro) { _, isPro in
            if isPro { close() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(GoStatsTheme.textPrimary).frame(width: 72, height: 72)
                Image(systemName: "soccerball")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 6) {
                Text("GoalStats")
                    .font(.system(size: 28, weight: .bold))
                Text("PRO")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(GoStatsTheme.accent))
            }
            .foregroundStyle(GoStatsTheme.textPrimary)
            Text(highlight.map { "\($0.title) is a Pro feature." } ?? "Coach smarter from the sideline.")
                .font(.system(size: 16))
                .foregroundStyle(GoStatsTheme.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(orderedPerks) { perk in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: perk.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(perk == highlight ? .white : GoStatsTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(perk == highlight ? GoStatsTheme.accent : GoStatsTheme.surface))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                        Text(perk.detail)
                            .font(.system(size: 13))
                            .foregroundStyle(GoStatsTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Rectangle().fill(GoStatsTheme.divider).frame(height: 1)
            Text("Always free: live match tracking, subs and minutes, halves or quarters, season and player stats, editing past matches, and your first team.")
                .font(.system(size: 12))
                .foregroundStyle(GoStatsTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(GoStatsTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, y: GoStatsTheme.cardShadowY)
        )
    }

    @ViewBuilder
    private var plans: some View {
        if pro.products.isEmpty {
            HStack(spacing: 10) {
                if pro.isLoading { ProgressView() }
                Text(pro.isLoading ? "Loading plans…" : "Plans unavailable right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(GoStatsTheme.textMuted)
                if !pro.isLoading {
                    Button("Retry") { Task { await pro.loadProducts() } }
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            VStack(spacing: 10) {
                ForEach(pro.products, id: \.id) { product in
                    planRow(product)
                }
            }
        }
    }

    private func planRow(_ product: Product) -> some View {
        let isYearly = product.id == ProStore.yearlyID
        let isSelected = product.id == selectedID
        return Button {
            Haptics.light()
            selectedID = product.id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? GoStatsTheme.textPrimary : GoStatsTheme.textMuted)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.system(size: 16, weight: .semibold))
                        if isYearly, let save = pro.yearlySavingsPercent, save > 0 {
                            Text("SAVE \(save)%")
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(0.5)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(GoStatsTheme.positive))
                        }
                    }
                    if isYearly, let monthlyEquivalent = monthlyEquivalent(product) {
                        Text("\(monthlyEquivalent)/month, billed yearly")
                            .font(.system(size: 12))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    } else {
                        Text("Billed monthly")
                            .font(.system(size: 12))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    }
                }
                Spacer()
                Text(product.displayPrice + (isYearly ? "/yr" : "/mo"))
                    .font(.system(size: 16, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(GoStatsTheme.textPrimary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? GoStatsTheme.textPrimary : GoStatsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task { await pro.purchase(product) }
            } label: {
                ZStack {
                    if pro.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(subscribeTitle)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                        .fill(GoStatsTheme.textPrimary)
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedProduct == nil || pro.isLoading)

            Text("Auto-renews until cancelled. Cancel anytime in Settings › Apple ID › Subscriptions.")
                .font(.system(size: 11))
                .foregroundStyle(GoStatsTheme.textMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Button("Restore Purchases") { Task { await pro.restore() } }
                Button("Terms") { openURL(ProStore.termsURL) }
                Button("Privacy") { openURL(ProStore.privacyURL) }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(GoStatsTheme.textPrimary.opacity(0.7))
        }
        .padding(.horizontal, GoStatsTheme.cardMargin)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(GoStatsTheme.bg.opacity(0.96).ignoresSafeArea())
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    private var subscribeTitle: String {
        guard let p = selectedProduct else { return "Subscribe" }
        return p.id == ProStore.yearlyID ? "Subscribe for \(p.displayPrice)/year" : "Subscribe for \(p.displayPrice)/month"
    }

    private func monthlyEquivalent(_ yearly: Product) -> String? {
        let perMonth = yearly.price / 12
        return perMonth.formatted(yearly.priceFormatStyle)
    }
}
