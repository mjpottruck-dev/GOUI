import SwiftUI

struct PricingView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @Environment(\.dismiss) private var dismiss

    @State private var isRestoring = false
    @State private var showContactSales = false

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header
                        planCard(plan: .free, price: "Free")
                        planCard(plan: .playerPro, price: "$4.99 / month")
                        planCard(plan: .coachPro, price: "$9.99 / month")
                        planCard(plan: .clubPro, price: "Contact sales")
                        restoreButton
                        debugSwitcher
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("GoStats Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                AnalyticsService.shared.log(.upgradeViewed)
            }
            .alert("Purchase Failed", isPresented: Binding(get: { subscriptionManager.lastPurchaseError != nil }, set: { _ in })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionManager.lastPurchaseError ?? "Unknown error")
            }
            .alert("Contact Sales", isPresented: $showContactSales) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Email sales@gostats.app to start a Club Pro plan.")
            }
        }
    }

    private var header: some View {
        LiquidGlassContainer(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Unlock GoStats Pro")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)
                Text("Pro unlocks unlimited exports, advanced analytics, and full highlights tools.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private func planCard(plan: Plan, price: String) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                        Text(plan.subtitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    Spacer()
                    Text(price)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(planBenefits(plan), id: \.self) { benefit in
                        Label(benefit, systemImage: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text)
                    }
                }

                HStack {
                    if subscriptionManager.currentPlan == plan {
                        Text("Current Plan")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.primary)
                    } else {
                        Button {
                            if plan == .clubPro {
                                showContactSales = true
                            } else {
                                Task { await subscriptionManager.purchase(plan: plan) }
                            }
                        } label: {
                            Text(plan == .clubPro ? "Contact Sales" : "Upgrade")
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

                    Spacer()
                }
            }
        }
    }

    private var restoreButton: some View {
        Button {
            isRestoring = true
            Task {
                await subscriptionManager.restorePurchases()
                isRestoring = false
            }
        } label: {
            HStack(spacing: 8) {
                if isRestoring {
                    ProgressView()
                }
                Text("Restore Purchases")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }

    private var debugSwitcher: some View {
        #if DEBUG
        return AnyView(
            LiquidGlassContainer(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DEBUG PLAN SWITCHER")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.primary)
                    Picker("Plan", selection: Binding(
                        get: { subscriptionManager.currentPlan },
                        set: { subscriptionManager.updatePlanForDebug($0) }
                    )) {
                        ForEach(Plan.allCases) { plan in
                            Text(plan.displayName).tag(plan)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        )
        #else
        return AnyView(EmptyView())
        #endif
    }

    private func planBenefits(_ plan: Plan) -> [String] {
        switch plan {
        case .free:
            return [
                "Limited exports",
                "Clip sampling",
                "Basic stats"
            ]
        case .playerPro:
            return [
                "Unlimited exports",
                "Player highlights",
                "Advanced analytics"
            ]
        case .coachPro:
            return [
                "Unlimited exports",
                "Team analytics",
                "Full video clips"
            ]
        case .clubPro:
            return [
                "Club dashboard",
                "Team rollups",
                "Dedicated support"
            ]
        }
    }
}
